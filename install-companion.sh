#!/bin/bash
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Run this as root on the Proxmox host."
command -v pct >/dev/null || die "pct not found. Run this on a Proxmox VE host."

# Prompt for container number, name, password, and network mode
read -p "Enter container number (e.g., 100): " CT_NUMBER
[[ "$CT_NUMBER" =~ ^[0-9]+$ ]] || die "Container number must be numeric."
if pct status "$CT_NUMBER" >/dev/null 2>&1; then die "Container $CT_NUMBER already exists."; fi

read -p "Enter container name: " CT_NAME
[ -n "$CT_NAME" ] || die "Container name cannot be empty."

read -sp "Enter password for the container: " CT_PASSWORD
echo
[ ${#CT_PASSWORD} -ge 5 ] || die "Password must be at least 5 characters."

read -sp "Confirm password for the container: " CT_PASSWORD_CONFIRM
echo
[ "$CT_PASSWORD" = "$CT_PASSWORD_CONFIRM" ] || die "Passwords do not match."

read -p "Enter VLAN tag (leave blank for none): " CT_VLAN
if [ -n "$CT_VLAN" ]; then
    [[ "$CT_VLAN" =~ ^[0-9]+$ ]] && [ "$CT_VLAN" -ge 1 ] && [ "$CT_VLAN" -le 4094 ] || die "VLAN tag must be a number between 1 and 4094."
    VLAN_CONFIG=",tag=$CT_VLAN"
else
    VLAN_CONFIG=""
fi

read -p "Use DHCP for networking? (y/n): " USE_DHCP

if [[ "$USE_DHCP" =~ ^[Yy]$ ]]; then
    NET_CONFIG="name=eth0,bridge=vmbr0,ip=dhcp$VLAN_CONFIG"
else
    read -p "Enter the container IP address with CIDR subnet mask (e.g., 10.0.0.50/24): " CT_IP_CIDR
    read -p "Enter the gateway IP address (e.g., 10.0.0.1): " CT_GATEWAY

    # Validate IP/CIDR format, e.g. 10.0.0.50/24
    if [[ ! "$CT_IP_CIDR" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        die "Invalid IP address format for $CT_IP_CIDR. Expected format: X.X.X.X/CIDR (e.g., 10.0.0.50/24)."
    fi

    CT_IP="${CT_IP_CIDR%/*}"
    CT_PREFIX="${CT_IP_CIDR#*/}"

    for octet in ${CT_IP//./ }; do
        [ "$octet" -le 255 ] || die "Invalid IP address format for $CT_IP_CIDR."
    done
    [ "$CT_PREFIX" -ge 0 ] && [ "$CT_PREFIX" -le 32 ] || die "Invalid CIDR prefix /$CT_PREFIX. Must be between 0 and 32."

    if [[ ! "$CT_GATEWAY" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || [ "${CT_GATEWAY##*.}" -gt 255 ]; then
        die "Invalid gateway IP address format for $CT_GATEWAY."
    fi

    NET_CONFIG="name=eth0,bridge=vmbr0,ip=$CT_IP_CIDR,gw=$CT_GATEWAY$VLAN_CONFIG"
fi

VMID=$CT_NUMBER

# --- Pick a storage that can hold container root filesystems ---
# Prefer local-lvm, then local, then whatever is available.
mapfile -t ROOT_STORAGES < <(pvesm status -content rootdir 2>/dev/null | awk 'NR>1 && $3=="active" {print $1}')
[ ${#ROOT_STORAGES[@]} -gt 0 ] || die "No active storage supports container root filesystems (content type 'rootdir')."

CT_STORAGE=""
for pref in local-lvm local; do
    for s in "${ROOT_STORAGES[@]}"; do
        if [ "$s" = "$pref" ]; then CT_STORAGE="$s"; break 2; fi
    done
done
[ -n "$CT_STORAGE" ] || CT_STORAGE="${ROOT_STORAGES[0]}"

if [ ${#ROOT_STORAGES[@]} -gt 1 ]; then
    echo "Available rootfs storages: ${ROOT_STORAGES[*]}"
    read -p "Storage to use [$CT_STORAGE]: " STORAGE_INPUT
    if [ -n "$STORAGE_INPUT" ]; then CT_STORAGE="$STORAGE_INPUT"; fi
fi
echo "Using storage: $CT_STORAGE"

# --- Pick a storage that can hold templates, and make sure we have one ---
TPL_STORAGE=$(pvesm status -content vztmpl 2>/dev/null | awk 'NR>1 && $3=="active" {print $1; exit}' || true)
[ -n "$TPL_STORAGE" ] || die "No active storage supports container templates (content type 'vztmpl')."

# Only consider templates built for this host's architecture; the appliance
# list carries arm64 builds too, and those sort after amd64.
HOST_ARCH=$(dpkg --print-architecture 2>/dev/null || true)
[ -n "$HOST_ARCH" ] || HOST_ARCH=amd64

# The Companion installer targets bookworm-era Debian, so prefer 12 and only
# fall back to the newest release on offer. Override with PREFERRED_DEBIAN=13.
PREFERRED_DEBIAN="${PREFERRED_DEBIAN:-12}"

# Newest entry matching the preferred release, else newest overall.
pick_template() {
    local list pick
    list=$(cat)
    pick=$(echo "$list" | grep -- "debian-${PREFERRED_DEBIAN}-standard" | sort -V | tail -n1 || true)
    [ -n "$pick" ] || pick=$(echo "$list" | sort -V | tail -n1 || true)
    echo "$pick"
}

# Reuse an already-downloaded Debian template if present.
TEMPLATE=$(pveam list "$TPL_STORAGE" 2>/dev/null | awk -v a="$HOST_ARCH" '$1 ~ /debian-.*-standard/ && index($1, "_" a ".") > 0 {print $1}' | pick_template || true)

if [ -z "$TEMPLATE" ]; then
    echo "No Debian $HOST_ARCH template found on $TPL_STORAGE. Downloading..."
    pveam update >/dev/null 2>&1 || true
    TPL_NAME=$(pveam available --section system 2>/dev/null | awk -v a="$HOST_ARCH" '$2 ~ /debian-.*-standard/ && index($2, "_" a ".") > 0 {print $2}' | pick_template || true)
    [ -n "$TPL_NAME" ] || die "Could not find a Debian $HOST_ARCH standard template in the appliance list."
    pveam download "$TPL_STORAGE" "$TPL_NAME" || die "Failed to download template $TPL_NAME."
    TEMPLATE="$TPL_STORAGE:vztmpl/$TPL_NAME"
fi
echo "Using template: $TEMPLATE"

# Create the container
pct create "$VMID" "$TEMPLATE" \
    -hostname "$CT_NAME" \
    -rootfs "$CT_STORAGE:8" \
    -memory 1024 \
    -cores 2 \
    -net0 "$NET_CONFIG" \
    -password "$CT_PASSWORD" \
    -start 1 || die "pct create failed. Nothing was installed."

echo "Container $CT_NAME (ID: $VMID) created and started."

# Wait for the container to finish booting and get networking
for i in $(seq 1 30); do
    if pct exec "$VMID" -- test -e /run/systemd/system 2>/dev/null; then
        break
    fi
    sleep 2
done
pct exec "$VMID" -- true 2>/dev/null || die "Container $VMID is not responding to pct exec."

# Run installation commands inside container
pct exec "$VMID" -- bash -s <<'EOF' || die "In-container setup failed."
    set -euo pipefail
    echo 'Running as root...'
    whoami

    echo -n 'Waiting for network... '
    for i in $(seq 1 30); do
        if getent hosts deb.debian.org >/dev/null 2>&1; then break; fi
        sleep 2
    done
    echo 'Done.'

    rm -f /tmp/companion-update.tar.gz

    echo -n 'Updating package lists... '
    apt-get update -y -o Acquire::http::Pipeline-Depth=0 -o APT::Cache-Limit=100000000 > /dev/null 2>&1
    echo 'Done.'

    echo -n 'Installing sudo and curl... '
    apt-get install -y --no-install-recommends sudo curl ca-certificates > /dev/null 2>&1
    echo 'Done.'

    echo 'Downloading and installing Companion...'
    curl -fsSL https://raw.githubusercontent.com/bitfocus/companion-pi/main/install.sh | bash
    echo 'Companion installation completed.'

    echo 'Enabling Companion service to start on boot...'
    systemctl enable companion
    echo 'Done.'

    echo 'Verifying Companion service...'
    systemctl list-unit-files --type=service | grep companion
    echo 'Done.'

    echo 'Companion has been installed and set up to start on boot.'
EOF

# Reboot container
pct reboot "$VMID"
echo "Container $CT_NAME (ID: $VMID) setup complete and rebooting."
echo "Companion will be at http://<container-ip>:8000"

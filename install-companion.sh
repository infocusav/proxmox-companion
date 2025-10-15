#!/bin/bash

# Prompt for container number, name, password, and network mode
read -p "Enter container number (e.g., 100): " CT_NUMBER
read -p "Enter container name: " CT_NAME
read -sp "Enter password for the container: " CT_PASSWORD
echo
read -p "Use DHCP for networking? (y/n): " USE_DHCP

if [[ "$USE_DHCP" =~ ^[Yy]$ ]]; then
    NET_CONFIG="name=eth0,bridge=vmbr0,ip=dhcp"
else
    read -p "Enter the container IP address (e.g., 10.0.0.50): " CT_IP
    read -p "Enter the gateway IP address (e.g., 10.0.0.1): " CT_GATEWAY

    # Basic IP address validation (less restrictive than before)
    if [[ ! "$CT_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || [ "${CT_IP##*.}" -gt 255 ]; then
        echo "Invalid IP address format for $CT_IP."
        exit 1
    fi

    if [[ ! "$CT_GATEWAY" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || [ "${CT_GATEWAY##*.}" -gt 255 ]; then
        echo "Invalid gateway IP address format for $CT_GATEWAY."
        exit 1
    fi

    NET_CONFIG="name=eth0,bridge=vmbr0,ip=$CT_IP/24,gw=$CT_GATEWAY"
fi

VMID=$CT_NUMBER

# Create the container
pct create $VMID /var/lib/vz/template/cache/debian-11-standard_11.7-1_amd64.tar.zst \
    -hostname $CT_NAME \
    -rootfs local-lvm:8 \
    -memory 512 \
    -cores 2 \
    -net0 $NET_CONFIG \
    -password $CT_PASSWORD \
    -start 1

echo "Container $CT_NAME (ID: $VMID) created and started."

# Wait a bit before executing post-install commands
sleep 5

# Run installation commands inside container
pct exec $VMID -- bash <<'EOF'
    echo 'Running as root...'
    whoami

    echo 'Skipping DNS check for faster setup...'
    rm -f /tmp/companion-update.tar.gz

    echo -n 'Updating package lists... '
    apt-get update -y -o Acquire::http::Pipeline-Depth=0 -o APT::Cache-Limit=100000000 > /dev/null 2>&1
    echo 'Done.'

    echo -n 'Installing sudo and curl... '
    apt-get install -y --no-install-recommends sudo curl > /dev/null 2>&1
    echo 'Done.'

    echo 'Downloading and installing Companion...'
    curl https://raw.githubusercontent.com/bitfocus/companion-pi/main/install.sh | bash
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
pct reboot $VMID
echo "Container $CT_NAME (ID: $VMID) setup complete and rebooting."

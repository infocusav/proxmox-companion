#!/bin/bash

# Prompt for container number, name, and password
read -p "Enter container number (e.g., 100): " CT_NUMBER
read -p "Enter container name: " CT_NAME
read -sp "Enter password for the container: " CT_PASSWORD
echo

# Set the configuration for the container
VMID=$CT_NUMBER
CT_IP="192.168.100.${CT_NUMBER}"  # Simple IP logic based on container number

# Validate IP address format
if [[ ! "$CT_IP" =~ ^192\.168\.1\.[0-9]+$ ]] || [ "${CT_IP##*.}" -gt 255 ]; then
    echo "Invalid IP address format for $CT_IP. Please ensure the IP is in the range 192.168.100.0-255."
    exit 1
fi

# Create the container using 'pct' command with the .zst template
pct create $VMID /var/lib/vz/template/cache/debian-11-standard_11.7-1_amd64.tar.zst \
    -hostname $CT_NAME \
    -rootfs local-lvm:8 \
    -memory 512 \
    -cores 2 \
    -net0 name=eth0,bridge=vmbr0,ip=$CT_IP/24,gw=192.168.1.1 \
    -password $CT_PASSWORD \
    -start 1

echo "Container $CT_NAME (ID: $VMID) created and started with IP $CT_IP."

# Ensure the container is running before proceeding
sleep 5  # Give it a few seconds to fully start

# Run the installation commands in the container
pct exec $VMID -- bash <<'EOF'
    # Ensure we are root and have all privileges
    echo 'Running as root...'
    whoami

    echo 'Updating package lists...'
    apt-get update -y || { echo "Failed to update packages."; exit 1; }

    echo 'Upgrading installed packages...'
    apt-get upgrade -y || { echo "Failed to upgrade packages."; exit 1; }

    echo 'Installing sudo and curl...'
    apt-get install -y sudo curl || { echo "Failed to install sudo or curl."; exit 1; }

    # Add user (if not already present)
    if ! id -u $USER &>/dev/null; then
        echo 'Creating user $USER...'
        useradd -m -s /bin/bash $USER
        echo "$USER:$CT_PASSWORD" | chpasswd
        usermod -aG sudo $USER
    else
        echo "User $USER already exists, skipping creation."
    fi

    # Install the Companion package
    echo 'Installing Companion...'
    curl https://raw.githubusercontent.com/bitfocus/companion-pi/main/install.sh | bash || { echo "Failed to install Companion."; exit 1; }

    # Enable Companion to start on boot
    echo 'Enabling Companion service to start on boot...'
    sudo systemctl enable companion || { echo "Failed to enable Companion service."; exit 1; }

    # Verify the Companion service
    echo 'Listing systemd services...'
    sudo systemctl list-unit-files --type=service

    echo 'Companion has been installed and set up to start on boot.'
EOF

echo "Container $CT_NAME (ID: $VMID) has completed all post-creation tasks."

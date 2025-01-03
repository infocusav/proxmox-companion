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
if [[ ! "$CT_IP" =~ ^192\.168\.100\.[0-9]+$ ]] || [ "${CT_IP##*.}" -gt 255 ]; then
    echo "Invalid IP address format for $CT_IP. Please ensure the IP is in the range 192.168.100.0-255."
    exit 1
fi

# Create the container using 'pct' command with the .zst template
pct create $VMID /var/lib/vz/template/cache/debian-11-standard_11.7-1_amd64.tar.zst \
    -hostname $CT_NAME \
    -rootfs local-lvm:8 \
    -memory 512 \
    -cores 2 \
    -net0 name=eth0,bridge=vmbr0,ip=$CT_IP/24,gw=192.168.100.1 \
    -password $CT_PASSWORD \
    -start 1

echo "Container $CT_NAME (ID: $VMID) created and started with IP $CT_IP."

# After container creation, install packages and configure the container

# Start the container
pct enter $VMID <<'EOF'
    # Update package lists
    apt-get update -y

    # Upgrade all existing packages
    apt-get upgrade -y

    # Install sudo and curl
    apt-get install -y sudo curl

    # Add the user (if not already added) for running sudo commands
    useradd -m -s /bin/bash $USER
    echo "$USER:$USER_PASSWORD" | chpasswd
    usermod -aG sudo $USER

    # Install the Companion package
    curl https://raw.githubusercontent.com/bitfocus/companion-pi/main/install.sh | bash

    # Enable Companion to start on boot
    sudo systemctl enable companion

    # Verify if Companion is installed and running
    sudo systemctl list-unit-files --type=service

    echo "Companion has been installed and set up to start on boot."
EOF

echo "Container $CT_NAME (ID: $VMID) has completed all post-creation tasks."

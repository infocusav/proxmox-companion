#!/bin/bash

# Variables for container creation
CTID=1000                    # ID of the container
VMID=1010                    # VMID for container
HOSTNAME="companion-container" # Container hostname
STORAGE="local"               # Storage for the container's disk

# Update package list and upgrade installed packages
echo "Updating package list and upgrading installed packages..."
apt update && apt upgrade -y

# Install curl if not installed
if ! command -v curl &> /dev/null; then
    echo "curl not found, installing..."
    apt install curl -y
fi

# Install Companion from GitHub
echo "Installing Companion from GitHub..."
curl https://raw.githubusercontent.com/bitfocus/companion-pi/main/install.sh | bash

# Create a Proxmox container
echo "Creating a Proxmox container with ID $CTID..."
pct create $CTID local:vztmpl/debian-12-standard_12.0-1_amd64.tar.gz \
    -hostname $HOSTNAME \
    -rootfs $STORAGE:8G \
    -net0 name=eth0,bridge=vmbr0,ip=dhcp \
    -memory 1024 \
    -cores 2 \
    -start 1

# Wait for container to start
echo "Waiting for container to start..."
sleep 10

# Install curl and sudo inside the container
echo "Installing curl and sudo inside the container..."
pct exec $CTID -- apt update
pct exec $CTID -- apt install curl sudo -y

# Install Companion inside the container
echo "Installing Companion inside the container..."
pct exec $CTID -- curl https://raw.githubusercontent.com/bitfocus/companion-pi/main/install.sh | bash

echo "Companion installation is complete!"

# You can now access Companion via the IP and port 8000.
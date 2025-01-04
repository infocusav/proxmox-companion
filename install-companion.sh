#!/bin/bash

# Prompt for container number, name, password, IP address, and gateway
read -p "Enter container number (e.g., 100): " CT_NUMBER
read -p "Enter container name: " CT_NAME
read -sp "Enter password for the container: " CT_PASSWORD
echo
read -p "Enter the container IP address (e.g., 192.168.0.x): " CT_IP
read -p "Enter the gateway IP address (e.g., 192.168.0.1): " CT_GATEWAY

# Validate IP address format (ensure it falls in the 192.168.x.x range)
if [[ ! "$CT_IP" =~ ^192\.168\.[0-9]+\.[0-9]+$ ]] || [ "${CT_IP##*.}" -gt 255 ]; then
    echo "Invalid IP address format for $CT_IP. Please ensure the IP is in the range 192.168.x.x."
    exit 1
fi

# Validate gateway IP address format
if [[ ! "$CT_GATEWAY" =~ ^192\.168\.[0-9]+\.[0-9]+$ ]] || [ "${CT_GATEWAY##*.}" -gt 255 ]; then
    echo "Invalid gateway IP address format for $CT_GATEWAY. Please ensure the gateway is in the range 192.168.x.x."
    exit 1
fi

# Set the configuration for the container
VMID=$CT_NUMBER

# Create the container using 'pct' command with the .zst template
pct create $VMID /var/lib/vz/template/cache/debian-11-standard_11.7-1_amd64.tar.zst \
    -hostname $CT_NAME \
    -rootfs local-lvm:8 \
    -memory 512 \
    -cores 2 \
    -net0 name=eth0,bridge=vmbr0,ip=$CT_IP/24,gw=$CT_GATEWAY \
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

    # Skip DNS check, assume it is configured
    echo 'Skipping DNS check for faster setup...'

    # Clear previous incomplete Companion download
    rm -f /tmp/companion-update.tar.gz

    # Update package lists with a loading indicator
    echo -n 'Updating package lists... '
    apt-get update -y -o Acquire::http::Pipeline-Depth=0 -o APT::Cache-Limit=100000000 > /dev/null 2>&1
    echo 'Done.'

    # Install only the necessary packages without recomm

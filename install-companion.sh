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

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

# Check if the template exists
TEMPLATE_PATH="/var/lib/vz/template/cache/debian-11-standard_11.7-1_amd64.tar.gz"
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "Template not found, downloading..."
    wget http://download.proxmox.com/iso/debian-11-standard_11.7-1_amd64.tar.gz -P /var/lib/vz/template/cache/
    if [ $? -ne 0 ]; then
        echo "Failed to download the template. Exiting."
        exit 1
    fi
    echo "Template downloaded successfully."
fi

# Check if there is enough space in the thin pool
THIN_POOL_FREE_SPACE=$(vgs --noheadings -o vg_free --units m | awk '{print $1}' | sed 's/M//')
if [ "$THIN_POOL_FREE_SPACE" -lt 1000 ]; then
    echo "Warning: Thin pool free space is low ($THIN_POOL_FREE_SPACE MB). Consider increasing the pool size."
    read -p "Do you want to continue with low space? (y/n): " CONTINUE
    if [[ "$CONTINUE" != "y" ]]; then
        echo "Exiting due to low space."
        exit 1
    fi
fi

# Create the container using 'pct' command
pct create $VMID $TEMPLATE_PATH \
    -hostname $CT_NAME \
    -rootfs local-lvm:8 \
    -memory 512 \
    -cores 2 \
    -net0 name=eth0,bridge=vmbr0,ip=$CT_IP/24,gw=192.168.100.1 \
    -password $CT_PASSWORD \
    -start 1

echo "Container $CT_NAME (ID: $VMID) created and started with IP $CT_IP."

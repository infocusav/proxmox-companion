#!/bin/bash

# Check if user is root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit
fi

# Prompt for container details
read -p "Enter Container ID (e.g. 101): " CTID
read -p "Enter Hostname (default: container${CTID}): " HOSTNAME
HOSTNAME=${HOSTNAME:-container${CTID}}

read -p "Enter Template name (default: local:vztmpl/debian-11-standard_11.0-1_amd64.tar.gz): " TEMPLATE
TEMPLATE=${TEMPLATE:-local:vztmpl/debian-11-standard_11.0-1_amd64.tar.gz}

read -p "Enter Storage (default: local-lvm): " STORAGE
STORAGE=${STORAGE:-local-lvm}

read -p "Enter Disk size in GB (default: 8): " DISK_SIZE
DISK_SIZE=${DISK_SIZE:-8}

read -p "Enter Number of CPU cores (default: 2): " CPU_CORES
CPU_CORES=${CPU_CORES:-2}

read -p "Enter Memory size in MB (default: 1024): " MEMORY
MEMORY=${MEMORY:-1024}

read -p "Enter Bridge interface (default: vmbr0): " BRIDGE
BRIDGE=${BRIDGE:-vmbr0}

# Ensure IP address is provided
while [[ -z "$IP_ADDRESS" ]]; do
  read -p "Enter IP address (e.g. 192.168.1.100/24): " IP_ADDRESS
done

read -p "Enter Gateway (default: 192.168.1.1): " GATEWAY
GATEWAY=${GATEWAY:-192.168.1.1}

# Create the container
echo "Creating container..."
pct create $CTID $TEMPLATE \
  -hostname $HOSTNAME \
  -storage $STORAGE \
  -rootfs ${STORAGE}:${DISK_SIZE} \
  -net0 name=eth0,bridge=$BRIDGE,ip=$IP_ADDRESS,gw=$GATEWAY \
  -cores $CPU_CORES \
  -memory $MEMORY \
  -onboot 1

if [ $? -eq 0 ]; then
  echo "Container $CTID created successfully."
  echo "Starting container..."
  pct start $CTID
  echo "Container $CTID started."
else
  echo "Failed to create container."
  exit 1
fi

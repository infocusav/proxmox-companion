#!/bin/bash

# Check if user is root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit
fi

# Prompt for container details with defaults
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

# Default network values
DEFAULT_IP="192.168.1.200/24"
DEFAULT_GATEWAY="192.168.1.1"

read -p "Enter IP address (default: $DEFAULT_IP): " IP_ADDRESS
IP_ADDRESS=${IP_ADDRESS:-$DEFAULT_IP}

read -p "Enter Gateway (default: $DEFAULT_GATEWAY): " GATEWAY
GATEWAY=${GATEWAY:-$DEFAULT_GATEWAY}

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

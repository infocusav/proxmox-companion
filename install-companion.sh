#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   __  __      _ _____ 
  / / / /__   (_) __(_)
 / / / / __ \/ / /_/ / 
/ /_/ / / / / / __/ /  
\____/_/ /_/_/_/ /_/   
 
EOF
}
header_info

if ! grep -q -m1 'avx[^ ]*' /proc/cpuinfo; then
  echo "AVX instruction set is not supported on this CPU."
  exit
fi
echo -e "Loading..."
APP="Unifi"
variables
color
catch_errors

# Prompt for user input
echo "Please provide the following details for container creation:"

# Container ID
read -p "Container ID (Default: $NEXTID): " CT_ID
CT_ID=${CT_ID:-$NEXTID}  # Default to NEXTID if not provided

# Hostname
read -p "Hostname (Default: $NSAPP): " HN
HN=${HN:-$NSAPP}  # Default to NSAPP if not provided

# Disk Size
read -p "Disk Size (Default: 8GB): " DISK_SIZE
DISK_SIZE=${DISK_SIZE:-"8G"}  # Default to "8G" if not provided

# RAM Size
read -p "RAM Size (Default: 2048MB): " RAM_SIZE
RAM_SIZE=${RAM_SIZE:-2048}  # Default to 2048MB if not provided

# CPU Cores
read -p "CPU Cores (Default: 2): " CORE_COUNT
CORE_COUNT=${CORE_COUNT:-2}  # Default to 2 if not provided

# Bridge
read -p "Bridge (Default: vmbr0): " BRG
BRG=${BRG:-"vmbr0"}  # Default to vmbr0 if not provided

# Network (DHCP)
read -p "Network (Default: dhcp): " NET
NET=${NET:-"dhcp"}  # Default to "dhcp" if not provided

# Gateway (optional)
read -p "Gateway (Optional, leave empty for default): " GATE

# Display the user's input
echo -e "\nYou entered the following settings:"
echo "Container ID: $CT_ID"
echo "Hostname: $HN"
echo "Disk Size: $DISK_SIZE"
echo "RAM Size: $RAM_SIZE"
echo "CPU Cores: $CORE_COUNT"
echo "Bridge: $BRG"
echo "Network: $NET"
echo "Gateway: $GATE"

# Build the container
echo "Creating the container..."

# Create the container
sudo pct create $CT_ID $STORAGE:vztmpl/$OS_TEMPLATE \
    -hostname $HN \
    -rootfs $STORAGE:$DISK_SIZE \
    -net0 name=eth0,bridge=$BRG,ip=$NET \
    -memory $RAM_SIZE \
    -cores $CORE_COUNT \
    -start 1

# Wait for the container to start
echo "Waiting for container to start..."
sleep 10

msg_ok "Container created successfully!"
echo -e "${APP}${CL} should be reachable by going to the following URL.\n"
echo -e "${BL}https://${IP}:8443${CL} \n"

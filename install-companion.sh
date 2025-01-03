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

function prompt_for_input() {
  echo "Please provide the following details for the container setup:"
  
  # Prompt for Container ID
  read -p "Container ID: " CT_ID
  CT_ID=${CT_ID:-$NEXTID}  # If empty, use the NEXTID from build.func
  
  # Prompt for Hostname
  read -p "Hostname (default: ${NSAPP}): " HN
  HN=${HN:-$NSAPP}  # Default to $NSAPP if not provided
  
  # Prompt for Disk Size
  read -p "Disk Size (default: 8GB): " DISK_SIZE
  DISK_SIZE=${DISK_SIZE:-"8G"}  # Default to "8G" if not provided
  
  # Prompt for CPU cores
  read -p "CPU cores (default: 2): " CORE_COUNT
  CORE_COUNT=${CORE_COUNT:-2}  # Default to 2 if not provided
  
  # Prompt for RAM Size
  read -p "RAM Size (default: 2048MB): " RAM_SIZE
  RAM_SIZE=${RAM_SIZE:-2048}  # Default to 2048MB if not provided
  
  # Prompt for Bridge
  read -p "Bridge (default: vmbr0): " BRG
  BRG=${BRG:-"vmbr0"}  # Default to vmbr0 if not provided
  
  # Prompt for Network (DHCP or Static IP)
  read -p "Network (default: dhcp): " NET
  NET=${NET:-"dhcp"}  # Default to dhcp if not provided

  # Additional optional parameters
  read -p "Gateway (Leave empty for default): " GATE
  read -p "Disable IPv6 (default: no): " DISABLEIP6
  DISABLEIP6=${DISABLEIP6:-"no"}
  
  # Show all inputs to user
  echo -e "\nYou entered the following details for the container setup:"
  echo "Container ID: $CT_ID"
  echo "Hostname: $HN"
  echo "Disk Size: $DISK_SIZE"
  echo "CPU cores: $CORE_COUNT"
  echo "RAM Size: $RAM_SIZE"
  echo "Bridge: $BRG"
  echo "Network: $NET"
  echo "Gateway: $GATE"
  echo "Disable IPv6: $DISABLEIP6"
}

function create_container() {
  echo -e "\nCreating container with the provided settings..."

  # Create Proxmox container with the user inputs
  sudo pct create $CT_ID $STORAGE:vztmpl/$OS_TEMPLATE \
    -hostname $HN \
    -rootfs $STORAGE:$DISK_SIZE \
    -net0 name=eth0,bridge=$BRG,ip=$NET \
    -memory $RAM_SIZE \
    -cores $CORE_COUNT \
    -start 1

  # Wait for container to start
  echo "Waiting for container to start..."
  sleep 10
}

# Run the functions
prompt_for_input
create_container

msg_ok "Completed Successfully!\n"
echo -e "${APP}${CL} should be reachable by going to the following URL.\n"
echo -e "${BL}https://${IP}:8443${CL} \n"

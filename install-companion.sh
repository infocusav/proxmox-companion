#!/usr/bin/env bash
# Copyright (c) 2025 infocusav
# License: MIT

# Function to display header info
function header_info {
  clear
  cat <<"EOF"
   ___                                   
  / __|___ _ __  ___ _ _  __ _ _ __ _  _ 
 | (__/ _ \ '  \/ -_) ' \/ _ | '_ \ || |
  \___\___/_|_|_\___|_||_\__,_| .__/\_, |
                              |_|   |__/ 
EOF
}

header_info
echo -e "Loading..."
APP="Proxmox Companion"
var_disk="8"        # Disk size in GB
var_cpu="2"         # CPU cores
var_ram="1024"      # RAM in MB
var_os="debian"     # OS template
var_version="11"    # Debian version
BRG="vmbr0"         # Bridge interface
NET="192.168.1.200/24"  # Default IP address
GATE="192.168.1.1"      # Default Gateway

# Function to handle color output (this is just an example)
function color {
  CL="\033[0m"
  BL="\033[1;34m"
}

# Function to catch errors
function catch_errors {
  if [ $? -ne 0 ]; then
    echo -e "${CL}[ERROR] Something went wrong."
    exit 1
  fi
}

# Function to set container variables
function advanced_settings {
  CT_TYPE="1"        # Unprivileged container
  PW=""              # No password
  CT_ID=101          # Manually set a valid container ID (use the next available ID if needed)
  HN="companion"     # Hostname
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  NET="ip=$NET,gw=$GATE"
  APT_CACHER="http://your-apt-cacher-url" # Advanced option for apt-cacher
  APT_CACHER_IP="your-cacher-ip"
  DISABLEIP6="no"
  MTU="1500"
  SD="none"
  NS="none"
  MAC="00:11:22:33:44:55"
  VLAN="none"
  SSH="no"
  VERB="yes"
  
  # Output the advanced settings
  echo -e "Advanced Settings: "
  echo -e "CT_TYPE: $CT_TYPE"
  echo -e "PW: $PW"
  echo -e "CT_ID: $CT_ID"
  echo -e "HN: $HN"
  echo -e "DISK_SIZE: $DISK_SIZE"
  echo -e "CORE_COUNT: $CORE_COUNT"
  echo -e "RAM_SIZE: $RAM_SIZE"
  echo -e "NET: $NET"
  echo -e "APT_CACHER: $APT_CACHER"
  echo -e "APT_CACHER_IP: $APT_CACHER_IP"
  echo -e "DISABLEIP6: $DISABLEIP6"
  echo -e "MTU: $MTU"
  echo -e "SD: $SD"
  echo -e "NS: $NS"
  echo -e "MAC: $MAC"
  echo -e "VLAN: $VLAN"
  echo -e "SSH: $SSH"
  echo -e "VERB: $VERB"
}

# Function to build the container
function build_container {
  # Simulating the building of the container with a placeholder
  echo -e "Building container with the following settings:"
  echo -e "CT_TYPE: $CT_TYPE"
  echo -e "CT_ID: $CT_ID"
  echo -e "HN: $HN"
  echo -e "DISK_SIZE: $DISK_SIZE"
  echo -e "CORE_COUNT: $CORE_COUNT"
  echo -e "RAM_SIZE: $RAM_SIZE"
  echo -e "NET: $NET"
  echo -e "Building... (this is a placeholder)"
}

# Function to show success message
function msg_ok {
  echo -e "[SUCCESS] $1"
}

# Function to start the script
function start {
  echo -e "Starting the process..."
}

# Function to display description
function description {
  echo -e "This script creates a container with the advanced settings."
}

# Start process
start
advanced_settings
build_container
description
msg_ok "Completed Successfully!\n"

# Ensure correct IP is displayed for the URL
IP="${NET%%/*}"  # Extract the IP part from the network range

echo -e "${APP}${CL} should be reachable by going to the following URL.
         ${BL}http://$IP:80${CL} \n"

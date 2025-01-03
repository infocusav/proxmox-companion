#!/usr/bin/env bash

# Initialize MENU variable
MENU="default"  # You can change this value based on your needs

source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
# Copyright (c) 2025 infocusav
# License: MIT

function header_info {
  clear
  cat <<"EOF"
   ___                                   
  / __|___ _ __  ___ _ _  __ _ _ __ _  _ 
 | (__/ _ \ '  \/ -_) ' \/ _` | '_ \ || |
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
NET="dhcp"           # Default DHCP IP configuration
GATE="192.168.1.1"  # Default Gateway

variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"        # Unprivileged container
  PW=""              # No password
  CT_ID=$NEXTID      # Next available container ID
  HN="companion"     # Hostname
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  if [ "$NET" == "dhcp" ]; then
    NET="ip=dhcp"
  else
    NET="ip=192.168.1.200/24,gw=$GATE"
  fi
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP}${CL} should be reachable by going to the following URL.
         ${BL}http://${IP}:80${CL} \n"

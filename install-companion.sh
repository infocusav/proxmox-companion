#!/usr/bin/env bash
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
NET="192.168.1.200/24"  # Default IP address
GATE="192.168.1.1"      # Default Gateway
variables
color
catch_errors

function advanced_settings() {
  CT_TYPE="1"        # Unprivileged container
  PW=""              # No password
  CT_ID=$NEXTID      # Next available container ID
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
  echo_advanced
}

start
build_container
description
msg_ok "Completed Successfully!\n"
echo -e "${APP}${CL} should be reachable by going to the following URL.
         ${BL}http://${IP}:80${CL} \n"

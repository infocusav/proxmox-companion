#!/bin/bash

# Update package list and upgrade installed packages
echo "Updating package list and upgrading installed packages..."
sudo apt update && sudo apt upgrade -y

# Install curl and sudo
echo "Installing curl and sudo..."
sudo apt install curl sudo -y

# Install Companion from GitHub
echo "Installing Companion from GitHub..."
curl https://raw.githubusercontent.com/bitfocus/companion-pi/main/install.sh | bash

# Set Companion to start on boot
echo "Setting Companion to start on boot..."
sudo systemctl enable companion

# Verify Companion is enabled
echo "Verifying Companion service is enabled..."
sudo systemctl list-unit-files --type=service | grep companion

# Reboot the server
echo "Rebooting the server..."
sudo reboot

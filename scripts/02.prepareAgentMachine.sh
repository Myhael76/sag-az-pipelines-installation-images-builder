#!/bin/bash

. "${BUILD_SOURCESDIRECTORY}/scripts/setEnv.sh"
. "${SUIF_HOME}/01.scripts/commonFunctions.sh"

logI "Updating OS software"
sudo apt update
#sudo apt install cifs-utils samba-common samba winbind
logI "Installing required libraries"
sudo apt install cifs-utils wget apt-transport-https software-properties-common
logI "Installing powershell"
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
# Register the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb
# Update the list of packages after we added packages.microsoft.com
sudo apt-get update
# Install PowerShell
sudo apt-get install -y powershell
logI "Machine prepared successfully"
#!/bin/bash

echo "Build Software AG images"

echo "dumping environment"

env | sort

sudo apt update
sudo apt install cifs-utils samba-common system-config-samba samba winbind

echo "Secure file is $(secureInfo.secureFilePath)"

if [ ! -f "$(secureInfo.secureFilePath)" ]; then
  echo "Secure file path not present"
fi

echo "Sourcing secure information..."

. "$(secureInfo.secureFilePath)"

echo "mounting the given file share"
d=$(date +%y-%m-%dT%H.%M.%S_%3N)
wd=/tmp/work_$d

mkdir -p /tmp/share $wd

sudo mount -t cifs $AZ_SMB_PATH /tmp/share -o username=$SAG_AZ_SA_NAME,password=$AZ_SM_SHARE_KEY,serverino

echo "Mounted"

echo "Test 1" > $wd/session.log

mkdir -p /tmp/share/sessions
cp -r $wd /tmp/share/sessions


# TODO: work in progress
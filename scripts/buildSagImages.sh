#!/bin/bash

echo "Build Software AG images"

echo "dumping environment"

env | sort

sudo apt update
sudo apt install cifs-utils samba-common system-config-samba samba winbind

echo "Secure file is ${SECUREINFO_SECUREFILEPATH}"

if [ ! -f "${SECUREINFO_SECUREFILEPATH}" ]; then
  echo "Secure file path not present"
  exit 1
fi

echo "Sourcing secure information..."

chmod u+x "${SECUREINFO_SECUREFILEPATH}"
. "${SECUREINFO_SECUREFILEPATH}"

if [ -z ${SAG_AZ_SA_NAME+x} ]; then
  echo "Secure information has not been sourced correctly"
  exit 2
fi

echo "mounting the given file share"
d=$(date +%y-%m-%dT%H.%M.%S_%3N)
crtDay=$(date +%y-%m-%d)
export SUIF_FIXES_DATE_TAG="$crtDay"
wd=/tmp/work_$d

mkdir -p /tmp/share $wd

sudo mount -t cifs $AZ_SMB_PATH /tmp/share -o username=$SAG_AZ_SA_NAME,password=$AZ_SM_SHARE_KEY,serverino

echo "Mounted"

echo "Test 1" > $wd/session.log

mkdir -p /tmp/share/sessions
cp -r $wd /tmp/share/sessions


# TODO: work in progress
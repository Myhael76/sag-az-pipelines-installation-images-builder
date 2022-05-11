#!/bin/bash

echo "Build Software AG images"
echo "DEBUG - dumping environment"
env | sort

# local variables
SUIF_TAG="v.0.0.2-temp"
d=$(date +%y-%m-%dT%H.%M.%S_%3N)
crtDay=$(date +%y-%m-%d)
wd=/tmp/work_$d # our work directory
sd=/tmp/share   # share directory - images

# exports for current job
export SUIF_FIXES_DATE_TAG="$crtDay"

getSUIF(){
  export SUIF_HOME=/tmp/SUIF
  export SUIF_AUDIT_BASE_DIR=/tmp/SUIF_AUDIT
  mkdir -p "${SUIF_HOME}" "${SUIF_AUDIT_BASE_DIR}"
  pushd .
  cd /tmp/SUIF
  git clone -b "${SUIF_TAG}" --single-branch https://github.com/SoftwareAG/sag-unattented-installations.git
  popd
  if [ ! -f "${SUIF_HOME}/01.scripts/commonFunctions.sh" ]; then
    echo "SUIF clone unseccessful, cannot continue"
    exit 3
  fi
}
getSUIF
. ${SUIF_HOME}/01.scripts/commonFunctions.sh
logI "SUIF cloned in folder ${SUIF_HOME} and sourced"
logI "SUIF env after sourcing:"
env | grep SUIF_ | sort

updateMachine(){
  logI "Updating machine base software..."
  sudo apt update
  #sudo apt install cifs-utils samba-common samba winbind
  sudo apt install cifs-utils
}
updateMachine

if [ ! -f "${SECUREINFO_SECUREFILEPATH}" ]; then
  echo "Secure file path not present: ${SECUREINFO_SECUREFILEPATH}"
  exit 1
fi

logI "Sourcing secure information..."
chmod u+x "${SECUREINFO_SECUREFILEPATH}"
. "${SECUREINFO_SECUREFILEPATH}"

if [ -z ${SAG_AZ_SA_NAME+x} ]; then
  echo "Secure information has not been sourced correctly"
  exit 2
fi

mountImagesShare(){
  logI "mounting the given file share"
  mkdir -p $sd $wd
  sudo mount -t cifs "$AZ_SMB_PATH" "$sd" -o "vers=3.0,username=$SAG_AZ_SA_NAME,password=$AZ_SM_SHARE_KEY,dir_mode=0777,file_mode=0777"
  logI " Images share mounted, result $?"
  mkdir -p "$sd/sessions/$crtDay"
}
mountImagesShare

finally(){
  logI "Saving the audit"
  tar cvzf "$sd/sessions/$crtDay/s_$d.tgz" "${SUIF_AUDIT_BASE_DIR}"
}
finally
# TODO: work in progress
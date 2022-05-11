#!/bin/bash

echo "Build Software AG images"
echo "DEBUG - dumping environment"
env | sort

# local variables
SUIF_TAG="v.0.0.2-temp"
d=$(date +%y-%m-%dT%H.%M.%S_%3N)
crtDay=$(date +%y-%m-%d)
wd="/tmp/work_$d" # our work directory
sd="/tmp/share"   # share directory - images
binDir="$sd/bin"
installerSharedBin="$binDir/installer.bin"
sumBootstrapSharedBin="$binDir/sum-bootstrap.bin"

# exports for current job
exports(){
  export SUIF_FIXES_DATE_TAG="$crtDay"
  export SUIF_DEBUG_ON=1
  export SUIF_SDC_ONLINE_MODE=1 # tell SUIF we are downloading from SDC
  # we'll work with local binaries, as the mount may have low IOPS
  export SUIF_INSTALL_INSTALLER_BIN=/tmp/installer.bin
  export SUIF_PATCH_SUM_BOOSTSTRAP_BIN=/tmp/sum-bootstrap.bin
}
exports

getSUIF(){
  export SUIF_HOME=/tmp/SUIF
  export SUIF_AUDIT_BASE_DIR=/tmp/SUIF_AUDIT
  mkdir -p "${SUIF_HOME}" "${SUIF_AUDIT_BASE_DIR}"
  pushd .
  cd /tmp/SUIF
  git clone -b "${SUIF_TAG}" --single-branch https://github.com/SoftwareAG/sag-unattented-installations.git "${SUIF_HOME}"
  popd
  if [ ! -f "${SUIF_HOME}/01.scripts/commonFunctions.sh" ]; then
    echo "SUIF clone unseccessful, cannot continue"
    exit 3
  fi
}
getSUIF
. ${SUIF_HOME}/01.scripts/commonFunctions.sh
. ${SUIF_HOME}/01.scripts/installation/setupFunctions.sh
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
  logI "Mounting the given file share"
  mkdir -p "$sd"
  sudo mount -t cifs "$AZ_SMB_PATH" "$sd" -o "vers=3.0,username=$SAG_AZ_SA_NAME,password=$AZ_SM_SHARE_KEY,dir_mode=0777,file_mode=0777"
  resultMount=$?
  if [ $resultMount -ne 0 ]; then
    logE "Error mounting the images share, result $resultMount"
    exit 4
  fi
  logI "Creating work folder and assuring shared folders (${binDir})"
  mkdir -p "${binDir}" "$wd" "$sd/sessions/$crtDay"
  touch "${binDir}/lastMountTime"
}
mountImagesShare

assureBinaries(){
  if [ -f "${installerSharedBin}" ]; then
    logI "Copying installer binary from the share"
    cp "${installerSharedBin}" "${SUIF_INSTALL_INSTALLER_BIN}"
    logI "Installer binary copied"
  else
    logI "Downloading default SUIF installer binary"
    assureDefaultInstaller
    logI "Copying installer binary to the share"
    cp "${SUIF_INSTALL_INSTALLER_BIN}" "${installerSharedBin}"
    logI "Installer binary copied, result $?"
  fi

  if [ -f "${sumBootstrapSharedBin}" ]; then
    logI "Copying sum bootstrap binary from the share"
    cp "${sumBootstrapSharedBin}" "${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}"
    logI "Installer binary copied"
  else
    logI "Downloading default SUIF installer binary"
    assureDefaultSumBoostrap
    logI "Copying sum bootstrap to the share"
    cp "${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}" "${sumBootstrapSharedBin}"
    logI "SUM Bootstrap binary copied, result $?"
  fi
}
assureBinaries

assureSUM(){
  export SUM_HOME=/tmp/sumv11
  mkdir -p "${SUM_HOME}"
  bootstrapSum "${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}" "" "${SUM_HOME}"
}

finally(){
  logI "Saving the audit"
  tar cvzf "$sd/sessions/$crtDay/s_$d.tgz" "${SUIF_AUDIT_BASE_DIR}"
  logI "Unmounting the shared images folder"
  umount "$sd"
  logI "Unmounted, result is $?"
}
finally
# TODO: work in progress
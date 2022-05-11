#!/bin/bash

echo "Build Software AG images"
echo "DEBUG - dumping environment"
env | sort

# local variables
SUIF_TAG="v.0.0.3-temp"
d=$(date +%y-%m-%dT%H.%M.%S_%3N)
crtDay=$(date +%y-%m-%d)
wd="/tmp/work_$d" # our work directory
sd="/tmp/share"   # share directory - images
binDir="$sd/bin"
installerSharedBin="$binDir/installer.bin"
sumBootstrapSharedBin="$binDir/sum-bootstrap.bin"
# templates is a space delimited list of SUIF templates to compute the images for"
templates="UM/1011/RealmServer UM/1011/TemplateApplications MSR/1011/lean"
export SUIF_PRODUCT_IMAGES_PLATFORM="LNXAMD64"
export SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY="/tmp/products"
export SUIF_PRODUCT_IMAGES_SHARED_DIRECTORY="$sd/products"
export SUIF_FIX_IMAGES_OUTPUT_DIRECTORY="/tmp/fixes"
export SUIF_FIX_IMAGES_SHARED_DIRECTORY="$sd/fixes"

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
  sudo apt install cifs-utils wget apt-transport-https software-properties-common
  wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
  # Register the Microsoft repository GPG keys
  sudo dpkg -i packages-microsoft-prod.deb
  # Update the list of packages after we added packages.microsoft.com
  sudo apt-get update
  # Install PowerShell
  sudo apt-get install -y powershell
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
  export SUIF_SUM_HOME=/tmp/sumv11
  mkdir -p "${SUIF_SUM_HOME}"
  bootstrapSum "${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}" "" "${SUIF_SUM_HOME}"
}
assureSUM

# Parameters
# $1 -> setup template
generateFixesImageFromTemplate(){
  local lFixesSharedDir="${SUIF_FIX_IMAGES_SHARED_DIRECTORY}/${1}/${SUIF_FIXES_DATE_TAG}"
  local lFixesSharedImageFile="${lFixesSharedDir}/fixes.zip"
  if [ -f "${lFixesSharedImageFile}" ]; then
    logI "Fixes image for template ${1} and tag ${SUIF_FIXES_DATE_TAG} already exists, nothing to do."
    return 0
  fi

  logI "Addressing fixes image for setup template ${1} and tag ${SUIF_FIXES_DATE_TAG}..."
  local lFixesDir="${SUIF_FIX_IMAGES_OUTPUT_DIRECTORY}/${1}/${SUIF_FIXES_DATE_TAG}"
  mkdir -p ${lFixesDir}
  local lFixesImageFile="${lFixesDir}/fixes.zip"
  local lPermanentInventoryFile="${lFixesDir}/inventory.json"
  local lPermanentScriptFile="${lFixesDir}/createFixesImage.wmscript"

  if [ -f "${lFixesImageFile}" ]; then
    logI "Fixes image for template ${1} and tag ${SUIF_FIXES_DATE_TAG} already exists, nothing to do."
    return 0
  fi

  if [ -f "${lPermanentInventoryFile}" ];then
    logI "Inventory file ${lPermanentInventoryFile} already exists, skipping creation."
  else
    logI "Inventory file ${lPermanentInventoryFile} does not exists, creating now."
    pwsh "${SUIF_HOME}/01.scripts/pwsh/generateInventoryFileFromInstallScript.ps1" \
      -file "${SUIF_HOME}/02.templates/01.setup/${1}/template.wmscript" -outfile "${lPermanentInventoryFile}" \
      -sumPlatformString "${SUIF_PRODUCT_IMAGES_PLATFORM}"
  fi

  if [ -f "${lPermanentScriptFile}" ];then
    logI "Permanent script file ${lPermanentScriptFile} already exists, skipping creation..."
  else
    logI "Permanent script file ${lPermanentScriptFile} does not exist, creating now..."
    echo "# Generated" > "${lPermanentScriptFile}"
    echo "scriptConfirm=N" >> "${lPermanentScriptFile}"
    # use before reuse -> diagnosers not covered for now
    echo "installSP=N " >> "${lPermanentScriptFile}"
    echo "action=Create or add fixes to fix image" >> "${lPermanentScriptFile}"
    echo "selectedFixes=spro:all" >> "${lPermanentScriptFile}"
    echo "installDir=${lPermanentInventoryFile}" >> "${lPermanentScriptFile}"
    echo "imagePlatform=${SUIF_PRODUCT_IMAGES_PLATFORM}" >> "${lPermanentScriptFile}"
    echo "createEmpowerImage=C " >> "${lPermanentScriptFile}"
  fi

  local lCmd="./UpdateManagerCMD.sh -selfUpdate false -readScript "'"'"${lPermanentScriptFile}"'"'
  lCmd="${lCmd} -installDir "'"'"${lPermanentInventoryFile}"'"'
  lCmd="${lCmd} -imagePlatform ${SUIF_PRODUCT_IMAGES_PLATFORM}"
  lCmd="${lCmd} -createImage "'"'"${lFixesImageFile}"'"' 
  lCmd="${lCmd} -empowerUser ${SUIF_EMPOWER_USER}"
  echo "SUM command to execute: ${lCmd} -empowerPass ***"
  lCmd="${lCmd} -empowerPass '${SUIF_EMPOWER_PASSWORD}'"

  pushd . >/dev/null
  cd "${SUIF_SUM_HOME}/bin"
  controlledExec "${lCmd}" "Create-fixes-image-for-template-${1//\//-}-tag-${SUIF_FIXES_DATE_TAG}"
  local lResultFixCreation=$?
  popd >/dev/null
  logI "Fix image creation for template ${1} finished, result: ${lResultFixCreation}"

  logI "Uploading the fixes to the shared directory"
  mkdir -p "${lFixesSharedDir}"
  cp -r "${lFixesDir}/*" "${lFixesSharedDir}/"
  logI "Fixes uploaded to the shared directory"
}

# Parameters
# $1 -> setup template
generateProductsImageFromTemplate(){
  logI "Addressing products image for setup template ${1}..."
  local lProductsSharedImageFile="${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${1}/products.zip"
  if [ -f "${lProductsSharedImageFile}" ]; then
    logI "Products image for template ${1} already exists, nothing to do."
    return 0
  fi
  local lProductsImageFile="${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${1}/products.zip"
  local lDebugLogFile="${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${1}/debug.log"
  local lPermanentScriptFile="${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${1}/createProductImage.wmscript"
  if [ -f "${lPermanentScriptFile}" ]; then
    logI "Permanent product image creation script file already present..."
  else
    logI "Permanent product image creation script file not present, creating now..."
    # NOTE: Some variables will depend on the product version. Look at SUIF images generator if needed

    # current default
    local lSdcServerUrl="https\://sdc-hq.softwareag.com/cgi-bin/dataservewebM1011.cgi"

    mkdir -p "${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${1}"
    echo "###Generated" > "${lPermanentScriptFile}"
    echo "LicenseAgree=Accept" >> "${lPermanentScriptFile}"
    echo "InstallLocProducts=" >> "${lPermanentScriptFile}"
    cat "${SUIF_HOME}/02.templates/01.setup/${1}/template.wmscript" | \
        grep "InstallProducts" >> "${lPermanentScriptFile}"
    echo "imagePlatform=${SUIF_PRODUCT_IMAGES_PLATFORM}" >> "${lPermanentScriptFile}"
    echo "imageFile=${lProductsImageFile}" >> "${lPermanentScriptFile}"
    echo "ServerURL=${lSdcServerUrl}" >> "${lPermanentScriptFile}"

    logI "Permanent product image creation script file created"
  fi

  logI "Creating the volatile script ..."
  local lVolatileScriptFile="/dev/shm/SUIF/setup/templates/${1}/createProductImage.wmscript"
  mkdir -p "/dev/shm/SUIF/setup/templates/${1}/"
  cp "${lPermanentScriptFile}" "${lVolatileScriptFile}"
  #echo "Username=${SUIF_EMPOWER_USER}" >> "${lVolatileScriptFile}"
  #echo "Password=${SUIF_EMPOWER_PASSWORD}" >> "${lVolatileScriptFile}"
  logI "Volatile script created."
  ## TODO: check if error management enforcement is needed: what if the grep produced nothing?

  local lDebugOn=${SUIF_DEBUG_ON:-0}

  ## TODO: not space safe, but it shouldn't matter for now
  local lCmd="${SUIF_INSTALL_INSTALLER_BIN} -readScript ${lVolatileScriptFile}"
  if [ "${lDebugOn}" -ne 0 ]; then
      lCmd="${lCmd} -debugFile '${lDebugLogFile}' -debugLvl verbose"
  fi
  lCmd="${lCmd} -writeImage ${lProductsImageFile}"
  #explictly tell installer we are running unattended
  lCmd="${lCmd} -scriptErrorInteract no"

  # TODO: these are new options documented for creating docker images from installer
  lCmd="${lCmd} --username ${SUIF_EMPOWER_USER}"
  lCmd="${lCmd} --password"

  logI "Creating the product image ${lProductsImageFile}... "
  logD "Command is ${lCmd} ***"
  lCmd="${lCmd} '${SUIF_EMPOWER_PASSWORD}'"
  controlledExec "${lCmd}" "Create-products-image-for-template-${1//\//-}"
  resultCreateImage=$?
  if [ "${resultCreateImage}" -ne 0 ]; then
    logE "Error code ${resultCreateImage} while creating the product image"
    logE "Empower user is ${SUIF_EMPOWER_USER}"
    cp "${lVolatileScriptFile}" "${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${1}/"
  else
    logI "Image ${lProductsImageFile} creation completed successfully"
  fi
  rm -f "${lVolatileScriptFile}"

  logI "Uploading the products to the shared directory"
  mkdir -p "${SUIF_PRODUCT_IMAGES_SHARED_DIRECTORY}"
  cp -r "${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY}/${1}" "${SUIF_PRODUCT_IMAGES_SHARED_DIRECTORY}/"
  logI "Products uploaded to the shared directory"
}

processTemplates(){
  # assure directories
  mkdir -p \
    "$SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY" \
    "$SUIF_PRODUCT_IMAGES_SHARED_DIRECTORY" \
    "$SUIF_FIX_IMAGES_OUTPUT_DIRECTORY" \
    "$SUIF_FIX_IMAGES_SHARED_DIRECTORY"
  for template in $templates; do
    logI "Processing template ${template}..."
    generateProductsImageFromTemplate "${template}"
    generateFixesImageFromTemplate "${template}"
    logI "Template $template processed."
  done
}

processTemplates

finally(){
  logI "Saving the audit"
  tar cvzf "$sd/sessions/$crtDay/s_$d.tgz" "${SUIF_AUDIT_BASE_DIR}"
  logI "Unmounting the shared images folder"
  sudo umount "$sd"
  logI "Unmounted, result is $?"
}
finally
# TODO: work in progress
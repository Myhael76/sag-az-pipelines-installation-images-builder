#!/bin/bash

. ${BUILD_SOURCESDIRECTORY}/scripts/setEnv.sh
. ${SUIF_HOME}/01.scripts/commonFunctions.sh

if [ -f "${MY_installerSharedBin}" ]; then
  logI "Copying installer binary from the share"
  cp "${MY_installerSharedBin}" "${SUIF_INSTALL_INSTALLER_BIN}"
  logI "Installer binary copied"
else
  logI "Downloading default SUIF installer binary"
  assureDefaultInstaller
  logI "Copying installer binary to the share"
  cp "${SUIF_INSTALL_INSTALLER_BIN}" "${MY_installerSharedBin}"
  logI "Installer binary copied, result $?"
fi

if [ -f "${MY_sumBootstrapSharedBin}" ]; then
  logI "Copying sum bootstrap binary from the share"
  cp "${MY_sumBootstrapSharedBin}" "${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}"
  logI "SUM bootstrap binary copied"
else
  logI "Downloading default SUIF installer binary"
  assureDefaultSumBoostrap
  logI "Copying sum bootstrap to the share"
  cp "${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}" "${MY_sumBootstrapSharedBin}"
  logI "SUM Bootstrap binary copied, result $?"
fi
chmod u+x "${SUIF_INSTALL_INSTALLER_BIN}"
chmod u+x "${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}"

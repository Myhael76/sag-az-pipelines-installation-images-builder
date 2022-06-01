#!/bin/bash

. ${BUILD_SOURCESDIRECTORY}/scripts/setEnv.sh
. ${SUIF_HOME}/01.scripts/commonFunctions.sh
. ${SUIF_HOME}/01.scripts/installation/setupFunctions.sh

logI "Sourcing secure information..."
chmod u+x "${SDCCREDENTIALS_SECUREFILEPATH}"
. "${SDCCREDENTIALS_SECUREFILEPATH}"

logI "Installing Update Manager..."
mkdir -p "${SUIF_SUM_HOME}"
bootstrapSum "${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}" "" "${SUIF_SUM_HOME}"

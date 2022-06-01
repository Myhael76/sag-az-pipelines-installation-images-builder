#!/bin/bash

. ${BUILD_SOURCESDIRECTORY}/scripts/setEnv.sh
. ${SUIF_HOME}/01.scripts/commonFunctions.sh

logI "Saving the audit"
mkdir -p "$MY_sd/sessions/$MY_crtDay"
tar cvzf "$MY_sd/sessions/$MY_crtDay/s_$MY_d.tgz" "${SUIF_AUDIT_BASE_DIR}"

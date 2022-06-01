#!/bin/bash

# Pipeline parameters
export MY_SUIF_TAG=${MY_SUIF_TAG:-"main"} # Expect this to be a pipeline parameter
export MY_templates=${MY_templates:-"MSR/1011/lean"}

# local variables
export MY_d=$(date +%y-%m-%dT%H.%M.%S_%3N)
export MY_crtDay=$(date +%y-%m-%d)
export MY_sd="/tmp/share"   # share directory - images
export MY_binDir="$MY_sd/bin"
export MY_installerSharedBin="$MY_binDir/installer.bin"
export MY_sumBootstrapSharedBin="$MY_binDir/sum-bootstrap.bin"

# SUIF exports
export SUIF_AUDIT_BASE_DIR=/tmp/SUIF_AUDIT
# ATTN: SUIF_DEBUG_ON=1 produces more logs, but may leave some functions waiting for user input
#       do not use it for unattended "final" forms of the pipelines
export SUIF_DEBUG_ON=${SUIF_DEBUG_ON:-0} # Expect this to be a pipeline parameter
export SUIF_FIX_IMAGES_OUTPUT_DIRECTORY="/tmp/fixes"
export SUIF_FIX_IMAGES_SHARED_DIRECTORY="$MY_sd/fixes"
export SUIF_FIXES_DATE_TAG="$MY_crtDay"
export SUIF_HOME=/tmp/SUIF
export SUIF_INSTALL_INSTALLER_BIN=/tmp/installer.bin
export SUIF_PATCH_SUM_BOOSTSTRAP_BIN=/tmp/sum-bootstrap.bin
export SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY="/tmp/products"
export SUIF_PRODUCT_IMAGES_PLATFORM="LNXAMD64"
export SUIF_PRODUCT_IMAGES_SHARED_DIRECTORY="$MY_sd/products"
export SUIF_SDC_ONLINE_MODE=1 # tell SUIF we are downloading from SDC
export SUIF_SUM_HOME=/tmp/sumv11

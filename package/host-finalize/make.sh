#!/usr/bin/bash
source $(dirname "$0")/../common.sh

echo ">>>   Finalizing host directory"

# see host-finalize in Makefile
PATCHELF=${HOST_DIR}/bin/patchelf \
PARALLEL_JOBS=${MAXNUM_CPUS} \
PER_PACKAGE_DIR=${OUTPUT_DIR}/per-package \
${PROJECT_DIR}/support/scripts/fix-rpath host

PATCHELF=${HOST_DIR}/bin/patchelf \
PARALLEL_JOBS=${MAXNUM_CPUS} \
PER_PACKAGE_DIR=${OUTPUT_DIR}/per-package \
${PROJECT_DIR}/support/scripts/fix-rpath staging

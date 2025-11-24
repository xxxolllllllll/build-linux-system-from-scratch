#!/usr/bin/bash
source $(dirname "$0")/../common.sh

mkdir -p ${BUILD_DIR}
if [ -f ${BUILD_DIR}/build-time.log ]; then
	touch ${BUILD_DIR}/build-time.log
fi
mkdir -p ${HOST_DIR}
mkdir -p ${STAGING_DIR}
ln -snf ${STAGING_DIR} ${OUTPUT_DIR}/staging
mkdir -p ${TARGET_DIR}

#!/bin/bash
##
#  Copyright (C) 2015, Samsung Electronics, Co., Ltd.
#  Written by System S/W Group, S/W Platform R&D Team,
#  Mobile Communication Division.
#
#  Edited by Diep Quynh Nguyen (diepquynh1501)
##

set -e -o pipefail

DEFCONFIG=apq8084_sec_defconfig
VARIANT_DEFCONFIG=apq8084_sec_lentislte_skt_defconfig
SELINUX_DEFCONFIG=selinux_defconfig

NAME=RZ_kernel
VERSION=v1.0

export ARCH=arm
export LOCALVERSION=-${VERSION}

KERNEL_PATH=$(pwd)
KERNEL_ZIP=${KERNEL_PATH}/zip_kernel
KERNEL_ZIP_NAME=${NAME}_${VERSION}.zip
KERNEL_IMAGE=${KERNEL_ZIP}/zImage
DT_IMG=${KERNEL_ZIP}/dt.img
MODULES_PATH=${KERNEL_ZIP}/modules
OUTPUT_PATH=${KERNEL_PATH}/output

export CROSS_COMPILE=$(pwd)/arm-eabi-4.8/bin/arm-eabi-;

JOBS=`grep processor /proc/cpuinfo | wc -l`

# Colors
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

function build() {
	clear;

	BUILD_START=$(date +"%s");
	echo -e "$cyan"
	echo "***********************************************";
	echo "              Compiling RZ kernel          	     ";
	echo -e "***********************************************$nocol";
	echo -e "$red";

	if [ ! -e ${OUTPUT_PATH} ]; then
		mkdir ${OUTPUT_PATH};
	fi;

	echo -e "Initializing defconfig...$nocol";
	make O=output ${DEFCONFIG} VARIANT_DEFCONFIG=${VARIANT_DEFCONFIG} SELINUX_DEFCONFIG=${SELINUX_DEFCONFIG}
	echo -e "$red";
	echo -e "Building kernel...$nocol";
	make O=output -j${JOBS} CONFIG_NO_ERROR_ON_MISMATCH=y;
	make O=output -j${JOBS} dtbs;
	gcc -o ${KERNEL_PATH}/scripts/dtbTool ${KERNEL_PATH}/scripts/dtbtool.c
	./scripts/dtbTool -o ${DT_IMG} -s 2048 $(pwd)/output/arch/arm/boot/
	find ${KERNEL_PATH} -name "zImage" -exec mv -f {} ${KERNEL_ZIP} \;
	find ${KERNEL_PATH} -name "*.ko" -exec mv -f {} ${MODULES_PATH} \;

	BUILD_END=$(date +"%s");
	DIFF=$(($BUILD_END - $BUILD_START));
	echo -e "$yellow";
	echo -e "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol";
}

function make_zip() {
	echo -e "$red";
	echo -e "Making flashable zip...$nocol";

	cd ${KERNEL_ZIP};
	make -j${JOBS};
}

function clean() {
	echo -e "$red";
	echo -e "Cleaning build environment...$nocol";
	make -j${JOBS} mrproper;

	rm -rf ${OUTPUT_PATH};
	rm -f ${MODULES_PATH}/*.ko;
	rm -f ${DT_IMG};
	rm -f ${KERNEL_PATH}/scripts/dtbTool;

	cd ${KERNEL_ZIP};
	make -j${JOBS} clean;

	echo -e "$yellow";
	echo -e "Done!$nocol";
}

function main() {
	clear;
	if [ "${USE_CCACHE}" == "1" ]; then
		CCACHE_PATH=$(which ccache);
		export CROSS_COMPILE="${CCACHE_PATH} ${CROSS_COMPILE}";
		export JOBS=8;
		echo -e "$red";
		echo -e "You have enabled ccache through *export USE_CCACHE=1*, now using ccache...$nocol";
	fi;

	echo -e "********************************************************";
	echo "      RZ Kernel for Samsung Galaxy S5 LTE-A (SM-G906x)";
	echo -e "********************************************************";
	echo "Choices:";
	echo "1. Cleanup source";
	echo "2. Build kernel";
	echo "3. Build kernel then make flashable ZIP";
	echo "4. Make flashable ZIP package";
	echo "Leave empty to exit this script (it'll show invalid choice)";

	read -n 1 -p "Select your choice: " -s choice;
	case ${choice} in
		1) clean;;
		2) build;;
		3) build
		   make_zip;;
		4) make_zip;;
		*) echo
		   echo "Invalid choice entered. Exiting..."
		   sleep 2;
		   exit 1;;
	esac
}

main $@

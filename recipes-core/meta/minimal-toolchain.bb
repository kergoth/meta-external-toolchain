SUMMARY = "Meta package for building a minimal installable toolchain"
LICENSE = "MIT"

TOOLCHAIN_HOST_TASK = "packagegroup-cross-canadian-${MACHINE}"

inherit populate_sdk

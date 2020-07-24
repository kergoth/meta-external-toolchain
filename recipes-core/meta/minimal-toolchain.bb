SUMMARY = "Meta package for building a minimal installable toolchain"
LICENSE = "MIT"

inherit populate_sdk

TOOLCHAIN_HOST_TASK = "packagegroup-cross-canadian-${MACHINE}"
TOOLCHAIN_TARGET_TASK = "${@multilib_pkg_extend(d, 'packagegroup-core-standalone-sdk-target')} target-sdk-provides-dummy"

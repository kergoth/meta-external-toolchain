SUMMARY = "Meta package for building a minimal installable toolchain"
LICENSE = "MIT"

TOOLCHAIN_HOST_TASK = "packagegroup-cross-canadian-${MACHINE}"
TOOLCHAIN_TARGET_TASK_pn-minimal-toolchain = "${@multilib_pkg_extend(d, 'packagegroup-core-standalone-sdk-target')} target-sdk-provides-dummy"

inherit populate_sdk

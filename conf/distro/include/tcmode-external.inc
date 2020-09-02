# Allow overrides usage for tcmode
TCMODEOVERRIDES ?= "tcmode-external"
OVERRIDES_prepend_class-target = "${TCMODEOVERRIDES}:"
OVERRIDES_prepend_class-cross = "${TCMODEOVERRIDES}:"

# The alternative to these would be to retain entries in DEPENDS and restore the
# bits that obey it.
#
# Pull this in explicitly rather than via compilerlibs/gcc-runtime's DEPENDS
BASE_DEFAULT_DEPS_append_tcmode-external_class-target = " libgcc"
# Pull this in explicitly rather than via the libc's DEPENDS
BASE_DEFAULT_DEPS_append_tcmode-external_class-target = " linux-libc-headers"
# Pull this in explicitly rather than via gcc
BASE_DEFAULT_DEPS_append_tcmode-external_class-target = " virtual/${TARGET_PREFIX}binutils"

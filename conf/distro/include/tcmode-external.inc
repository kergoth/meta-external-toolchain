# Configuration to use external toolchain
EXTERNAL_TOOLCHAIN ??= "UNDEFINED"
# TODO: convert to EXTERNAL_TARGET_PREFIX
EXTERNAL_TARGET_SYS ??= "${TARGET_ARCH}-${TARGET_OS}"
EXTERNAL_TOOLCHAIN_BIN ??= "${EXTERNAL_TOOLCHAIN}/bin"
# TODO: add gcc multiarch triplet

# We don't care if this path references other variables
EXTERNAL_TOOLCHAIN[vardepvalue] = "${EXTERNAL_TOOLCHAIN}"

# External toolchain features.
#
#   locale-utf8-is-default: assume en_US is utf8, not en_US.UTF-8, as is the
#                           case for OE.
#   all-files-optional: make a failure to find files non-fatal
#   use-files-mirrors: check alternate paths for files using defined mirrors
EXTERNAL_TOOLCHAIN_FEATURES ??= ""

python () {
    oe.utils.features_backfill("EXTERNAL_TOOLCHAIN_FEATURES", d)
}

# Pull in our utility functions for use elsewhere
INHERIT += "external_global"

# FIXME: this is a temporary workaround
# Allow overrides usage for tcmode
TCMODEOVERRIDES ??= ""
TCMODEOVERRIDES_append_class-target = "tcmode-external:tcmode-${TCMODE}"
TCMODEOVERRIDES_append_class-cross = "tcmode-external:tcmode-${TCMODE}"
#TCMODEOVERRIDES = "tcmode-external"
#TCMODEOVERRIDES_append = ":tcmode-${TCMODE}"
OVERRIDES =. "${TCMODEOVERRIDES}:"

# Show current configuration
BUILDCFG_VARS += "TCMODE TCLIBC"

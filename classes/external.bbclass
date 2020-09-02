# NOTE: certain files should always be optional. *.a, .debug, locales
# TODO: write the sdk processing hook to emit recipefiles into the sdk. it
# should be enabled alongside emitting TUNE_PKGARCH, etc. Possibly a specific
# class or recipe for enabling/emitting external-compatible sdks.
# TODO: add a flag to allow use of variable references in the files lists, to
# be used in heuristic-mode operation
# TODO: add flag to make all files in the recipefiles optional
# TODO: add variable to control which files are optional, ex. *.a, .debug
# TODO: add logic to skip external if components are missing, but 1) this
# shouldn't be done for the main components, and 2) doing so requires the
# recipe to reparse when the external files and/or version change, so use of
# PKGV isn't viable there, and arguably should probably key the reparsing on
# every file we want from the external toolchain in such a case
# TODO: How do we best ensure we rebuild if the external toolchain changes?
# Should we just disable sstate and re-run once per build? Can we rely on all
# of the extracted versioning strings? I think we'd have to, unless we want to
# add every external file path to our file-checksums.
# I'd really like to avoid adding all the files to the checksums, and I'd like
# to avoid getting versions too if possible, but it doesn't seem viable.
# TODO: consider parsing an external metadata file with PV, LICENSE, then have
# the heuristic variant pull those via other means only if it's not available.

# Configuration to use external toolchain
EXTERNAL_TOOLCHAIN ??= "UNDEFINED"
# TODO: convert to EXTERNAL_TARGET_PREFIX
EXTERNAL_TARGET_SYS ??= "${TARGET_ARCH}-${TARGET_OS}"
EXTERNAL_TOOLCHAIN_BIN ??= "${EXTERNAL_TOOLCHAIN}/bin"

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

EXTERNAL_TOOLCHAIN_SYSROOT ??= "${@external_run(d, d.getVar('EXTERNAL_CC'), *(TARGET_CC_ARCH.split() + ['-print-sysroot'])).rstrip()}"
EXTERNAL_TOOLCHAIN_LIBROOT ??= "${@external_run(d, d.getVar('EXTERNAL_CC'), *(TARGET_CC_ARCH.split() + ['-print-file-name=crtbegin.o'])).rstrip().replace('/crtbegin.o', '')}"
EXTERNAL_LIBC_KERNEL_VERSION ??= "${@external_get_kernel_version("${EXTERNAL_TOOLCHAIN_SYSROOT}${prefix}")}"

EXTERNAL_CC ??= "${EXTERNAL_TARGET_SYS}-gcc"

def external_run(d, *args):
    """Convenience wrapper"""
    if (not d.getVar('TCMODE', True).startswith('external') or
            not d.getVar('EXTERNAL_TOOLCHAIN', True)):
        return 'UNKNOWN'

    sys.path.append(os.path.join(d.getVar('LAYERDIR_meta-external', True), 'lib'))
    import oe.external
    return oe.external.run(d, *args)

def external_get_kernel_version(p):
    import re
    for fn in ['include/linux/utsrelease.h', 'include/generated/utsrelease.h',
               'include/linux/version.h']:
        fn = os.path.join(p, fn)
        if os.path.exists(fn):
            break
    else:
        return ''

    try:
        f = open(fn)
    except IOError:
        pass
    else:
        with f:
            lines = f.readlines()

        for line in lines:
            m = re.match(r'#define LINUX_VERSION_CODE (\d+)$', line)
            if m:
                code = int(m.group(1))
                a = code >> 16
                b = (code >> 8) & 0xFF
                return '%d.%d' % (a, b)

    return ''

# Since these are prebuilt binaries, there are no source files to checksum for
# LIC_FILES_CHKSUM, so use the license from common-licenses
inherit common_license

LIC_FILES_CHKSUM_tcmode-external_class-target = "${COMMON_LIC_CHKSUM}"
LIC_FILES_CHKSUM_tcmode-external_class-cross = "${COMMON_LIC_CHKSUM}"

# Save files lists for recipes
inherit recipefiles

RECIPEFILES_DIR ?= "${EXTERNAL_TOOLCHAIN}/recipefiles"

EXTERNAL_ENABLED = ""
EXTERNAL_ENABLED_tcmode-external_class-target = "1"
EXTERNAL_ENABLED_tcmode-external_class-cross = "1"

PR_append_tcmode-external_class-target = ".external"
PR_append_tcmode-external_class-cross = ".external"

# Exclude default sources
SRC_URI_tcmode-external_class-target = ""
SRC_URI_tcmode-external_class-cross = ""
SRCPV_tcmode-external_class-target = ""
SRCPV_tcmode-external_class-cross = ""

NOEXEC_TASKS = ""
NOEXEC_TASKS_tcmode-external_class-target = "do_patch do_configure do_compile"
NOEXEC_TASKS_tcmode-external_class-cross = "do_patch do_configure do_compile"

python () {
    if d.getVar('EXTERNAL_ENABLED'):
        for task in d.getVar('NOEXEC_TASKS').split():
            d.setVarFlag(task, 'noexec', '1')
}

# We don't want to interact with the gcc stashed builddir
COMPILERDEP_tcmode-external_class-target = ""
COMPILERDEP_tcmode-external_class-cross = ""

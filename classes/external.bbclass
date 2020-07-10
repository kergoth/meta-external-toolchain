# NOTE: certain files should always be optional. *.a, .debug, locales
# TODO: write the sdk processing hook to emit recipefiles into the sdk. it
# should be enabled alongside emitting TUNE_PKGARCH, etc. Possibly a specific
# class or recipe for enabling/emitting external-compatible sdks.
#
# TODO: add a flag to allow use of variable references in the files lists, to
# be used in heuristic-mode operation
# TODO: add flag to make all files in the recipefiles optional
# TODO: add variable to control which files are optional, ex. *.a, .debug
#
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

# Since these are prebuilt binaries, there are no source files to checksum for
# LIC_FILES_CHKSUM, so use the license from common-licenses
inherit common_license

#PV .= "-external"

COMMON_LIC_CHKSUM_MIT = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

LIC_FILES_CHKSUM_tcmode-external = "${COMMON_LIC_CHKSUM}"

# We don't extract anything which will create S, and we don't want to see the
# warning about it
S_tcmode-external = "${WORKDIR}"

# Toolchain shipped binaries weren't necessarily built ideally
INSANE_SKIP_${PN}_append_tcmode-external = " ldflags textrel"

# Debug files may well have already been split out, or stripped out
INSANE_SKIP_${PN}_append_tcmode-external = " already-stripped"

# Missing build deps don't matter when we don't build anything
INSANE_SKIP_${PN}_append_tcmode-external = " build-deps"

RECIPEFILES_DIR ?= "${TOPDIR}/recipefiles"

def read_files_from_pkgdata(pkgdatafile, long=False):
    import json
    with open(pkgdatafile, 'r') as f:
        found = False
        for line in f:
            if line.startswith('FILES_INFO:'):
                found = True
                val = line.split(':', 1)[1].strip()
                dictval = json.loads(val)
                return sorted(dictval)

def import_from_filename(module_name, file_path):
    import importlib.util
    import sys

    spec = importlib.util.spec_from_file_location(module_name, file_path)
    if spec is not None:
        module = importlib.util.module_from_spec(spec)
    else:
        # Assumption
        loader = importlib.machinery.SourceFileLoader(module_name, file_path)
        module = loader.load_module()
    sys.modules[module_name] = module
    return module

def write_recipefiles_for_pkgs(pkglist, pkgdata_dir, filename):
    from pathlib import Path

    pkgdata_dir = Path(pkgdata_dir)
    allfiles = set()
    for pkg in pkglist:
        pkgdatafile = pkgdata_dir / 'runtime' / pkg
        allfiles |= set(read_files_from_pkgdata(pkgdatafile))

    outfile = Path(filename)
    outfile.parent.mkdir(parents=True, exist_ok=True)
    with outfile.open('w') as f:
        f.writelines(f + '\n' for f in sorted(allfiles))

python do_save_recipefiles () {
    import pathlib

    if not d.getVar('PACKAGES').strip():
        return

    utilpath = bb.utils.which(os.getenv('PATH'), 'oe-pkgdata-util')
    if not utilpath:
        bb.fatal('No oe-pkgdata-util found')
    oe_pkgdata_util = import_from_filename('oe_pkgdata_util', utilpath)

    pkgdata_dir = d.getVar('PKGDATA_DIR')
    pn = d.getVar('PN')
    recipefiles_dir = pathlib.Path(d.getVar('RECIPEFILES_DIR'))
    recipefiles = (recipefiles_dir / pn).with_suffix('.files')

    pkglist = oe_pkgdata_util.get_recipe_pkgs(pkgdata_dir, pn, unpackaged=False)
    write_recipefiles_for_pkgs(pkglist, pkgdata_dir, recipefiles)
}
addtask do_save_recipefiles after do_packagedata

def load_recipefiles(d):
    from pathlib import Path

    recipefiles_dir = Path(d.getVar('RECIPEFILES_DIR'))
    pn = d.getVar('PN')
    recipefiles_path = recipefiles_dir / Path(pn).with_suffix('.files')
    try:
        contents = recipefiles_path.read_text()
    except FileNotFoundError:
        bb.fatal('{}: file not found'.format(recipefiles_path))
    else:
        files = contents.splitlines()
    return files

EXCLUDED_EXTERNAL_FILES += "\
    ${sysconfdir}/default/volatiles \
"
EXCLUDED_EXTERNAL_FILES += "\
    .*\.debug \
    ${prefix}/src/debug \
"

# Packaging requires objcopy/etc for split and strip
PACKAGE_DEPENDS += "virtual/${MLPREFIX}${TARGET_PREFIX}binutils"

do_fetch[noexec] = "1"
do_unpack[noexec] = "1"
do_patch[noexec] = "1"
do_configure[noexec] = "1"
do_compile[noexec] = "1"

COMPILERDEP = ""

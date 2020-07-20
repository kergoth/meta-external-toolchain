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

# Save files lists for recipes
inherit recipefiles

PACKAGESPLITFUNCS_prepend = "external_systemd_adjust "

python external_systemd_adjust () {
    if not bb.utils.contains('DISTRO_FEATURES', 'systemd', True, False, d):
        return
    if not bb.data.inherits_class('systemd', d):
        return
    systemd_packages = d.getVar('SYSTEMD_PACKAGES')
    if not systemd_packages:
        return

    def get_package_var(d, var, pkg):
        val = (d.getVar('%s_%s' % (var, pkg)) or "").strip()
        if val == "":
            val = (d.getVar(var) or "").strip()
        return val

    searchpaths = [oe.path.join(d.getVar("sysconfdir"), "systemd", "system"),]
    searchpaths.append(d.getVar("systemd_system_unitdir"))

    for pkg_systemd in systemd_packages.split():
        for service in get_package_var(d, 'SYSTEMD_SERVICE', pkg_systemd).split():
            # Deal with adding, for example, 'ifplugd@eth0.service' from
            # 'ifplugd@.service'
            base = None
            at = service.find('@')
            if at != -1:
                ext = service.rfind('.')
                base = service[:at] + '@' + service[ext:]

            for path in searchpaths:
                if os.path.exists(oe.path.join(d.getVar("D"), path, service)):
                    break
                elif base is not None:
                    if os.path.exists(oe.path.join(d.getVar("D"), path, base)):
                        break
            else:
                d.delVar('SYSTEMD_SERVICE_%s' % pkg_systemd)
}

RECIPEFILES_DIR ?= "${EXTERNAL_TOOLCHAIN}/recipefiles"

EXTERNAL_ENABLED = ""
EXTERNAL_ENABLED_tcmode-external = "1"

PR_append_tcmode-external = ".external"

LIC_FILES_CHKSUM_tcmode-external = "${COMMON_LIC_CHKSUM}"

# We don't extract anything which will create S, and we don't want to see the
# warning about it
S_tcmode-external = "${WORKDIR}"

# Exclude default sources
SRC_URI_tcmode-external = ""

# Toolchain shipped binaries weren't necessarily built ideally
INSANE_SKIP_${PN}_append_tcmode-external = " ldflags textrel"

# Debug files may well have already been split out, or stripped out
INSANE_SKIP_${PN}_append_tcmode-external = " already-stripped"

# Missing build deps don't matter when we don't build anything
INSANE_SKIP_${PN}_append_tcmode-external = " build-deps"

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

EXCLUDED_EXTERNAL_FILES += "\
    ${sysconfdir}/default/volatiles \
"
EXCLUDED_EXTERNAL_FILES += "\
    .*\.debug \
    ${prefix}/src/debug \
"

# Packaging requires objcopy/etc for split and strip
PACKAGE_DEPENDS_append_tcmode-external = " virtual/${MLPREFIX}${TARGET_PREFIX}binutils"

NOEXEC_TASKS = ""
NOEXEC_TASKS_tcmode-external = "do_patch do_configure do_compile"

python () {
    for task in d.getVar('NOEXEC_TASKS').split():
        d.setVarFlag(task, 'noexec', '1')
}

COMPILERDEP_tcmode-external = ""

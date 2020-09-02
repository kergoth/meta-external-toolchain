inherit external

# We don't extract anything which will create S, and we don't want to see the
# warning about it
S_tcmode-external = "${WORKDIR}"

# Toolchain shipped binaries weren't necessarily built ideally
INSANE_SKIP_${PN}_append_tcmode-external = " ldflags textrel"

# Debug files may well have already been split out, or stripped out
INSANE_SKIP_${PN}_append_tcmode-external = " already-stripped"

# Missing build deps don't matter when we don't build anything
INSANE_SKIP_${PN}_append_tcmode-external = " build-deps"

EXCLUDED_EXTERNAL_FILES += "\
    ${sysconfdir}/default/volatiles \
    .*\.debug \
    ${prefix}/src/debug \
"

# Packaging requires objcopy/etc for split and strip
PACKAGE_DEPENDS_append_tcmode-external = " virtual/${MLPREFIX}${TARGET_PREFIX}binutils"

# Disable systemd service files which we don't have. This generally occurs when
# a recipe emits binary packages which include service files, but those packages
# aren't included in the particular sdk we're using.
PACKAGESPLITFUNCS_prepend = "systemd_disable_missing "

python systemd_disable_missing () {
    if not bb.data.inherits_class('systemd', d) or not bb.utils.contains('DISTRO_FEATURES', 'systemd', True, False, d):
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
                d.setVar('SYSTEMD_SERVICE_%s_remove' % pkg_systemd, service)
                d.setVar('SYSTEMD_SERVICE_remove', service)
}

python external_install () {
    import re
    import subprocess
    from collections import defaultdict
    from pathlib import Path

    files = load_recipefiles(d.getVar('RECIPEFILES_PATH'))

    by_dirname = defaultdict(set)
    for f in files:
        by_dirname[Path(f).parent].add(f)

    excluded = d.getVar('EXCLUDED_EXTERNAL_FILES').split()
    excluded_patterns = [re.compile(p.strip()) for p in excluded]

    sysroot = Path(d.getVar('EXTERNAL_TOOLCHAIN_SYSROOT'))
    if sysroot == 'UNKNOWN':
        bb.fatal('EXTERNAL_TOOLCHAIN_SYSROOT is UNKNOWN. Please configure or use a supported toolchain.')

    dest = Path(d.getVar('D'))
    for dirname, files in by_dirname.items():
        args = []
        for f in sorted(files):
            # FIXME: we can make the files mandatory by processing the
            # recipefiles in the sdk to exclude files not shipped with it
            if not any(pat.match(f) for pat in excluded_patterns):
                src = sysroot / Path(f).relative_to('/')
                if src.exists() or src.is_symlink():
                    args.append(src)

        if args:
            destdir = Path(str(dest) + str(dirname))
            destdir.mkdir(parents=True, exist_ok=True)
            args.append('{}/'.format(destdir))
            cmd = ['cp', '-PR', '--preserve=mode,timestamps', '--no-preserve=ownership'] + args
            bb.debug(1, subprocess.list2cmdline([str(a) for a in cmd]))
            subprocess.check_call(cmd)
}

fakeroot python do_install_external() {
    bb.note('Building externally')
    bb.build.exec_func('external_install', d)
    if d.getVar('do_install_extra'):
        bb.build.exec_func('do_install_extra', d)
}

python () {
    if d.getVar('EXTERNAL_ENABLED') == '1':
        d.setVar('do_install', d.getVar('do_install_external', False))
        d.setVarFlag('do_install', 'deps', ['do_fetch', 'do_unpack'])
        d.setVarFlag('do_install', 'python', '1')
}

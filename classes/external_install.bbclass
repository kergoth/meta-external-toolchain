inherit external

python external_install () {
    import re
    import subprocess
    from collections import defaultdict
    from pathlib import Path

    files = load_recipefiles(d)

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
            subprocess.check_call(['cp', '-PR', '--preserve=mode,timestamps', '--no-preserve=ownership'] + args)
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

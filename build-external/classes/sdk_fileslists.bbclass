POPULATE_SDK_POST_HOST_COMMAND .= "write_host_fileslists;"

python write_host_fileslists () {
    write_sdk_fileslists(d, target=False)
}

POPULATE_SDK_POST_TARGET_COMMAND .= "write_target_fileslists;"

python write_target_fileslists () {
    write_sdk_fileslists(d, target=True)
}

def write_sdk_fileslists(d, target=True):
    import ast
    from collections import defaultdict
    from pathlib import Path
    import oe.packagedata
    from oe.sdk import sdk_list_installed_packages

    if target:
        sysroot_name = d.getVar('REAL_MULTIMACH_TARGET_SYS')
        pkgdata_dir = Path(d.getVar('PKGDATA_DIR'))
    else:
        sysroot_name = sdk_sys = d.getVar('SDK_SYS')
        pkgdata_dir = Path(d.getVar('TMPDIR')) / 'pkgdata' / sdk_sys

    recipefiles = defaultdict(list)
    for pkg in sorted(sdk_list_installed_packages(d, target=target)):
        pkg_info = pkgdata_dir / 'runtime-reverse' / pkg
        pkg_name = os.path.basename(os.readlink(pkg_info))

        pkgdata = oe.packagedata.read_pkgdatafile(pkg_info)
        files_info = pkgdata.get('FILES_INFO')
        if files_info:
            files = ast.literal_eval(files_info).keys()
            recipefiles[pkgdata['PN']].extend(list(sorted(Path(f) for f in files)))

    sdkpath = d.getVar('SDKPATH')
    outdir = Path(d.getVar('SDK_OUTPUT')) / sdkpath.strip('/')
    for recipe, files in recipefiles.items():
        files = sdk_files_to_relative(files, target, sysroot_name, sdkpath)
        output = (outdir / 'fileslists' / sysroot_name / recipe).with_suffix('.list')
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(''.join('%s\n' % f for f in files))

def sdk_files_to_relative(files,target, sysroot_name, sdkpath):
    from pathlib import Path

    if target:
        for f in files:
            yield Path('sysroots') / sysroot_name / Path(f).relative_to('/')
    else:
        for f in files:
            yield Path('sysroots') / sysroot_name / Path(f).relative_to(sdkpath)

DEPLOY_DIR_RECIPEFILES = "${DEPLOY_DIR}/recipefiles"

SAVE_RECIPEFILES_DIR = "${WORKDIR}/save-recipefiles-${PN}"
SSTATETASKS += "do_save_recipefiles"
do_save_recipefiles[sstate-inputdirs] = "${SAVE_RECIPEFILES_DIR}"
do_save_recipefiles[sstate-outputdirs] = "${DEPLOY_DIR_RECIPEFILES}"

python do_save_recipefiles_setscene () {
    sstate_setscene(d)
}
addtask do_save_recipefiles_setscene
do_save_recipefiles[dirs] = "${SAVE_RECIPEFILES_DIR} ${B}"
do_save_recipefiles[cleandirs] = "${SAVE_RECIPEFILES_DIR}"
do_save_recipefiles[stamp-extra-info] = "${MACHINE_ARCH}"


do_save_recipefiles () {
    find . -not -type d | sed -e 's/^\.//' >"${SAVE_RECIPEFILES_DIR}/${PN}.files"
}
do_save_recipefiles[dirs] = "${D}"

addtask do_save_recipefiles after do_install before do_build

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

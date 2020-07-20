inherit external_install

# FILESEXTRAPATHS_prepend := "${THISDIR}/${BPN}:"
# SRC_URI_tcmode-external_append = " file://SUPPORTED"

stash_locale_cleanup_tcmode-external () {
    :
}

do_stash_locale_tcmode-external () {
    :
}

# Save the recipefiles list excluding the stashed locale files
SAVE_RECIPEFILES_D = "${WORKDIR}/recipefiles-d"

python do_save_recipefiles () {
    import shutil
    from pathlib import Path

    src = d.getVar('D')
    dest = Path(d.getVar('SAVE_RECIPEFILES_D'))

    if dest.exists():
        shutil.rmtree(dest)
    oe.path.copyhardlinktree(src, dest)
    bb.build.exec_func('stash_locale_recipefiles_cleanup', d)

    files = [Path(f).relative_to(dest) for f in oe.path.find(dest)]
    recipefiles = (Path(d.getVar('SAVE_RECIPEFILES_DIR')) / d.getVar('PN')).with_suffix('.files')
    recipefiles.write_text(''.join('/%s\n' % f for f in files))
}

stash_locale_recipefiles_cleanup() {
	stash_locale_cleanup ${SAVE_RECIPEFILES_D}
}

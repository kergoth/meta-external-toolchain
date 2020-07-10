inherit external_install

DEPENDS_REMOVE = "libgcc-initial"
DEPENDS_remove_tcmode-external = "${DEPENDS_REMOVE}"
DEPENDS_append_tcmode-external = " libgcc"

# # glibc's utils need libgcc
# # do_package[depends] += "${MLPREFIX}libgcc:do_packagedata"
# do_packagedata[depends] += "${MLPREFIX}libgcc:do_packagedata"
# do_package_write_ipk[depends] += "${MLPREFIX}libgcc:do_packagedata"
# do_package_write_deb[depends] += "${MLPREFIX}libgcc:do_packagedata"
# do_package_write_rpm[depends] += "${MLPREFIX}libgcc:do_packagedata"

# glibc may need libssp for -fstack-protector builds
#do_packagedata[depends] += "gcc-runtime:do_packagedata"

stash_locale_cleanup () {
    :
}

do_stash_locale () {
    :
}

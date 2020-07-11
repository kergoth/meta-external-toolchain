inherit external_cross

binutils_binaries = "ar as ld ld.bfd ld.gold nm objcopy objdump ranlib strip \
                     addr2line c++filt elfedit gprof readelf size \
                     strings"
EXTERNAL_CROSS_BINARIES = "${binutils_binaries}"

do_install_append_tcmode-external () {
    if [ ! -e ${D}${bindir}/${TARGET_PREFIX}ld.bfd ]; then
        ln -s ${TARGET_PREFIX}ld ${D}${bindir}/${TARGET_PREFIX}ld.bfd
    fi
}

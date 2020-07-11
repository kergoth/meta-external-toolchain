inherit external_cross

gcc_binaries = "gcc gcc-${PV} \
                gcc-ar gcc-nm gcc-ranlib cc gcov gcov-tool c++ g++ cpp gfortran"
EXTERNAL_CROSS_BINARIES = "${gcc_binaries}"

do_gcc_stash_builddir_tcmode-external () {
    :
}

python () {
    if d.getVar('TCMODE_EXTERNAL') == '1':
        lic_deps = d.getVarFlag('do_populate_lic', 'depends', False)
        d.setVarFlag('do_populate_lic', 'depends', lic_deps.replace('gcc-source-${PV}:do_unpack', ''))
        cfg_deps = d.getVarFlag('do_configure', 'depends', False)
        d.setVarFlag('do_configure', 'depends', cfg_deps.replace('gcc-source-${PV}:do_preconfigure', ''))
}

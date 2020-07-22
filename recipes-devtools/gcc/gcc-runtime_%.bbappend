inherit external_install

#do_install[deptask] += "do_populate_sysroot"
#RDEPENDS_${PN} += "libgcc"

python () {
    if d.getVar('EXTERNAL_ENABLED') == '1':
        lic_deps = d.getVarFlag('do_populate_lic', 'depends', False)
        d.setVarFlag('do_populate_lic', 'depends', lic_deps.replace('gcc-source-${PV}:do_unpack', ''))
        cfg_deps = d.getVarFlag('do_configure', 'depends', False)
        d.setVarFlag('do_configure', 'depends', cfg_deps.replace('gcc-source-${PV}:do_preconfigure', ''))
}

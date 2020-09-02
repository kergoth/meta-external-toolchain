# inherit external_install

# LOCALETREESRC = "${PKGD}"

# SRC_URI_tcmode-external += "file://SUPPORTED"
# FILESPATH_prepend_tcmode-external =. "${LAYERDIR_meta-external}/files:"

# python () {
#     if d.getVar('EXTERNAL_ENABLED') == '1':
#         bb.build.addtask('do_fetch', '', '', d)
#         bb.build.addtask('do_unpack', 'do_install', 'do_fetch', d)
# }

# do_install_extra () {
#     install -d ${D}${datadir}
# }

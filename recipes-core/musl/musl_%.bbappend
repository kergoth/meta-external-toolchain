inherit external_install

DEPENDS_REMOVE = "libgcc-initial"
DEPENDS_remove_tcmode-external = "${DEPENDS_REMOVE}"
DEPENDS_append_tcmode-external = " libgcc"

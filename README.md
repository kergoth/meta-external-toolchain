# meta-external OpenEmbedded/Yocto Layer

## Design

This external toolchain mode appends the existing oe-core recipes rather than
adding its own, both to reduce complexity and duplication of metadata and to
more closely align with what oe-core is doing.

This is in contrast with older implementations which use a single monolithic
recipe, as that approach has downsides, particularly for external toolchains
which include more content than you actually want to install, and you have to
hardcode the PROVIDES.

The largest task of this layer is to copy files from the external toolchain
sysroot and other appropriate paths into the destination during `do_install`,
while disabling compilation.

Original attempts used manual cp commands, while later versions of
meta-external-toolchain used a fuzzier, more heuristic approach with mirror
handling to support differing toolchain layouts.

This version simplifies installation and eases support of new external
toolchains by operating based on "recipe files". It expects a directory
containing one text file per recipe listing the files this recipe is expected
to install. There is no need to specify the files on a per-package basis, as
our use of the original oe-core recipes means we can use the existing FILES
variables to break it up into packages.

These files can be included in the external toolchain, or the default versions
in this layer can be used. If the latter is used with a custom toolchain, one
may wish to make a failure to locate every file non-fatal, and may also wish
to optionally enable mirror handling for differing layouts. This is supported
through `EXTERNAL_FEATURES`.

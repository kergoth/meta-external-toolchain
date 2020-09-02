import os.path
import re
import shlex
import subprocess
import oe.path
import bb


def run(d, cmd, *args):
    topdir = d.getVar('TOPDIR')
    toolchain_path = d.getVar('EXTERNAL_TOOLCHAIN')
    if toolchain_path:
        toolchain_bin = d.getVar('EXTERNAL_TOOLCHAIN_BIN')
        path = os.path.join(toolchain_bin, cmd)
        args = shlex.split(path) + list(args)

        try:
            output, _ = bb.process.run(args, cwd=topdir)
        except bb.process.CmdError as exc:
            bb.debug(1, str(exc))
        else:
            return output

    return 'UNKNOWN'

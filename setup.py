# Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

import os

from distutils.core import setup
from shutil import rmtree
from stat import S_IRWXO, S_IRWXG, S_IRWXU

import sys

name = "Shotgun Connectivity Test"
description = "Script for diagnosing connectivity issues with Shotgun"
setup_requirements = ["py2exe-py2==0.6.9"]

releases_dir = os.path.join('releases')
build_dir = os.path.join(releases_dir, 'build')

build_opts = {'build_base': build_dir}

def deltree(dpath):
    """Force-delete path and all contents"""
    if os.path.exists(dpath):
        for root, dirs, files in os.walk(dpath):
            for d in dirs:
                d = os.path.join(root, d)
                os.chmod(d, S_IRWXU | S_IRWXG | S_IRWXO)
            for f in files:
                f = os.path.join(root, f)
                os.chmod(f, S_IRWXU | S_IRWXG | S_IRWXO)
        # Delete the entire tree
        try:
            rmtree(dpath, ignore_errors=False)
        except OSError:
            raise EnvironmentError("Could not clean product path!")

def build_win32():
    import py2exe

    win32_bin_dir = os.path.join(releases_dir, "sgConnectivityTest")
    deltree(win32_bin_dir)

    py2exe_config = {'compressed': True,
                     'bundle_files': 1,
                     'includes': [],
                     'excludes': ['_gtkagg', '_tkagg', 'bsddb', 'curses', 'pywin.debugger',
                                  'pywin.debugger.dbgcon', 'pywin.dialogs', 'tcl', 'Tkconstants', 'Tkinter',
                                  # Large modules recommended for exclusion
                                  'doctest', 'pdb', 'unittest',
                                  ],
                     'dll_excludes': ['w9xpopen.exe', 'mswsock.dll', 'powrprof.dll'] # We really don't care about Win95/98. I think... :)
                     }
    setup(options={'py2exe': py2exe_config,
                   'build' : build_opts},
          console=['shotgun_connectivity_test.py'],
          zipfile=None)

if __name__ == '__main__':
    if sys.platform == "win32":
        build_win32()

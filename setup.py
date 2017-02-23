import glob
import os
import sys
from setuptools import setup
from setuptools.extension import Extension, Library
from setuptools.command.build_clib import build_clib


def list_files(path):
    for root, dirs, files in os.walk(path):
        for fname in files:
            yield os.path.join(root, fname)

        for dirname in dirs:
            for rpath in list_files(os.path.join(root, dirname)):
                yield rpath


basepath = os.path.normpath(r'atari_py/ale_interface/src')
modules = [os.path.join(basepath, os.path.normpath(path))
           for path in 'common controllers emucore emucore/m6502/src '
                       'emucore/m6502/src/bspf/src environment games '
                       'games/supported external external/TinyMT'.split()]
defines = []
sources = [os.path.join(basepath, 'ale_interface.cpp')]
includes = [basepath, os.path.join(basepath, 'os_dependent')]
includes += modules

for folder in modules:
    sources += glob.glob(os.path.join(folder, '*.c'))
    sources += glob.glob(os.path.join(folder, '*.c?[xp]'))

if sys.platform.startswith('linux'):
    defines.append(('BSPF_UNIX', None))
    for fname in 'SettingsUNIX.cxx OSystemUNIX.cxx FSNodePOSIX.cxx'.split():
        sources.append(os.path.join(basepath, 'os_dependent', fname))
elif sys.platform == "darwin":
    defines.append(('BSPF_MAC_OSX', None))
    includes.append(
        '/System/Library/Frameworks/vecLib.framework/Versions/Current/Headers')
elif sys.platform == "win32":
    defines.append(('BSPF_WIN32', None))
    for fname in 'SettingsWin32.cxx OSystemWin32.cxx FSNodeWin32.cxx'.split():
        sources.append(os.path.join(basepath, 'os_dependent', fname))


def rglob(path, pattern):
    return fnmatch.filter(list_files(path), pattern)


def find_include_dirs(root, fname):
    return {os.path.dirname(path)
            for path in rglob(root, '*' + fname)}


library_dirs = []
zlib_root = os.environ.get('ZLIB_ROOT')
if zlib_root is not None:
    import fnmatch

    zlib_includes = []

    zlib_dirs = find_include_dirs(zlib_root, 'zlib.h')
    if not zlib_dirs:
        raise ValueError("Failed to find 'zlib.h' under ZLIB_ROOT folder. "
                         "It looks like there is no zlib in supplied path.")
    zlib_includes += zlib_dirs

    zconf_dirs = find_include_dirs(zlib_root, 'zconf.h')
    if not zlib_includes:
        raise ValueError("Failed to find 'zconf.h' under ZLIB_ROOT folder. "
                         "Have you compiled zlib?")
    zlib_includes += zconf_dirs
    includes += zlib_includes

    zlib_libraries = set()

    # Try to compile a test program against zlib
    from distutils.ccompiler import get_default_compiler, new_compiler
    compiler = new_compiler(compiler=get_default_compiler())
    ext = compiler.static_lib_extension

    if os.name == 'nt':
        zlib_name = 'zlib'
    else:
        zlib_name = 'libz'
    zlib_lib_pattern = '%s*%s' % (zlib_name, ext)

    import tempfile
    from distutils.ccompiler import CompileError, LinkError
    tmp_dir = tempfile.mkdtemp()
    src_path = os.path.join(tmp_dir, 'zlibtest.c')
    with open(src_path, 'w') as f:
        f.write("#include <zlib.h>\nint main() { inflate(0, 0); return 0; }")
    try:
        for i, path in enumerate(rglob(zlib_root, '*' + zlib_lib_pattern)):
            tmp_dir_i = os.path.join(tmp_dir, str(i))
            zlib_library = os.path.splitext(os.path.basename(path))[0]
            zlib_library_dir = os.path.dirname(path)
            try:
                objects = compiler.compile([src_path], tmp_dir_i,
                                           include_dirs=zlib_includes)
                compiler.link_executable(objects, 'zlibtest', tmp_dir_i,
                                         libraries=[zlib_library],
                                         library_dirs=[zlib_library_dir])
            except (CompileError, LinkError) as e:
                pass  # skip this library as malformed
            else:
                zlib_libraries.add((zlib_library, zlib_library_dir))
                break
    finally:
        import shutil
        shutil.rmtree(tmp_dir, ignore_errors=True)

    if not zlib_libraries:
        raise ValueError("Failed to find a suitable library (%s) under "
                         "ZLIB_ROOT folder. Have you compiled zlib?"
                         % zlib_lib_pattern)

    # Priority to static library (Windows)
    for zlib_library, zlib_library_dir in zlib_libraries:
        if 'static' in zlib_library:
            break
    library_dirs.append(zlib_library_dir)
else:
    if os.name == 'nt':
        zlib_library = 'zlib'
    else:
        zlib_library = 'z'

import numpy
'''
ale_interface = Library('ale_interface',
                define_macros=defines,
                sources=sources,
                include_dirs=includes,
                libraries=[zlib_library],
                library_dirs=library_dirs,
                )

ale_interface = 'ale_interface', dict(
                macros=defines,
                sources=sources,
                include_dirs=includes,
                libraries=[zlib_library],
                library_dirs=library_dirs,

                extra_compile_args=['/Zi'],
                extra_link_args=['/DEBUG'],
                )

ale = Extension('atari_py.ale',
                language='c++',
                define_macros=defines,
                sources=['atari_py/ale.pyx'],
                #libraries=[ale_interface],

                libraries=[zlib_library],
                library_dirs=library_dirs,

                extra_compile_args=['/Zi'],
                extra_link_args=['/DEBUG'],
                include_dirs=['atari_py', 'atari_py/ale_interface/src', numpy.get_include()] )

'''
ale = Extension('atari_py.ale',
                language='c++',
                define_macros=defines,
                sources=['atari_py/ale.pyx'] + sources,

                libraries=[zlib_library],
                library_dirs=library_dirs,

                #libraries=[ale_interface],
                extra_compile_args=['/Zi'],
                extra_link_args=['/DEBUG'],
                include_dirs=['atari_py', 'atari_py/ale_interface/src', numpy.get_include()] + includes )
#'''

setup(name='atari-py',
      version='0.0.18',
      description='Python bindings to Atari games',
      url='https://github.com/openai/atari-py',
      author='OpenAI',
      author_email='info@openai.com',
      license='',
      packages=['atari_py'],
      package_data={'atari_py': ['atari_roms/*']},
      #cmdclass={'build_ext': build_ext},
      #cmdclass={'build_clib': build_clib},
      #libraries = [ale_interface],
      ext_modules=[ale],
      install_requires=['numpy', 'six'],
      tests_require=['nose2']
      )

# atari_py

[![Build Status](https://travis-ci.org/openai/atari-py.svg?branch=master)](https://travis-ci.org/openai/atari-py)

A packaged and slightly-modified version of [https://github.com/bbitmaster/ale_python_interface](https://github.com/bbitmaster/ale_python_interface).

## Installation

To install via pip, run:

```pip install atari-py```
That *should* install a correct binary verison for your OS. If that does not work (or if you would like get the latest-latest
version, or you just want to tinker with the code yourself) see next paragraph. 

## Installation from source

  -  make sure you have `git`, `cmake` and `zlib1g` system packages installed 
  -  clone the repo
  -  run `pip install -e .`


### Common issues

- If `zlib` cannot be found by compiler - check if it is installed in your
  system. You can provide `zlib` path by setting `ZLIB_ROOT` environment
  variable or directly to `pip` like this:
  `pip install --global-option=build_ext --global-option="-L/path/to/zlib/lib" --global-option="-I/path/to/zlib/include" atari-py`

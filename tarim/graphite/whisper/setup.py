#!/usr/bin/env python

import os
from glob import glob
from distutils.core import setup


setup(
  name='whisper',
  version='0.9.12',
  url='http://graphite-project.github.com/',
  author='Chris Davis',
  author_email='chrismd@gmail.com',
  license='Apache Software License 2.0',
  description='Fixed size round-robin style database',
  py_modules=['whisper'],
  scripts=glob('bin/*'),
)

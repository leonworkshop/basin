#!/usr/bin/env python
# Copyright (c) 2014 LogStream
# All rights reserved.
#

import setuptools

try:
  import multiprocessing
except ImportError:
  pass

# requires python > 2.7
setuptools.setup(
  setup_requires=['pbr'],
  pbr=True)

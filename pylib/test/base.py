#
# Copyright 2014, logstream ltd, all rights reserved.
#

"""Base Test Case for all unit tests"""

import os
import os.path
import sys
import testtools

sys.path.append(".")

from pylib.common import log

ROOTDIR = os.path.dirname(__file__)
FILEDIR = os.path.join(ROOTDIR, 'files')

class BaseTestCase(testtools.TestCase):

  def setUp(self):
    super(BaseTestCase, self).setUp()

    # initialize logging
    opts = { 'verbose': True, 'console': True }
    log.init_logging(opts)

  def tearDown(self):
    super(BaseTestCase, self).tearDown()
    pass

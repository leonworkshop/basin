#!/usr/bin/env python
#
# Copyright 2014, Leon's Workshop Ltd, All rights reserved.
#

import sys
import argparse
import os
import socket
import time

sys.path.append('.')

from pylib.common import exception as exp
from pylib.common import utils
from pylib.common import log
from pylib.framework.lib import xmt

"""
Global options
"""


def parseArguments():
    parser = argparse.ArgumentParser(description="shoowo Sichuan post boot tool")
    parser.add_argument('--verbose', action='store_true',
                        required=False,
                        help="Print out more debugging information")
    parser.add_argument('--console',
                        required=False, action='store_true',
                        help="Print out log to console")
    parser.add_argument('--logfile', default='/var/log/shoowo/sichuan_deploy.log',
                        help="Logging file")
    parser.add_argument('--pmt',
                        default='/opt/shoowo/skeleton/xmt/pmt.yaml',
                        help="Phase mapping table file path")
    args = parser.parse_args()
    return args


def prepare():
    args = parseArguments()
    log.init_logging({'verbose': args.verbose,
                      'console': args.console,
                      'logfile': args.logfile,
                      })

    if not os.path.isfile(args.pmt):
        log.error("Error: file %s not exists", args.pmt)
        raise exp.InvalidConfigurationOption(opt_name='pmt', opt_value=args.pmt)

    return args


def main():
    try:
        # prepare the working environment
        args = prepare()

        # load PMT/BMT table
        xmt_mgr = xmt.XmtManager()
        xmt_mgr.load(xmt.XMT_TYPE_PMT, args.pmt)

        hostname = socket.gethostname()
        pmt_entry = xmt_mgr.get_entry(xmt.XMT_TYPE_PMT, hostname)
        log.debug("Get the PMT entry: %s", pmt_entry)

        # modify puppet config with proper environment value
        cmd = "sed -i \'s/environment=production$/environment=" + \
              pmt_entry['environment'] + "/g\' /etc/puppet/puppet.conf"
        utils.run_command(cmd)

    except Exception as e:
        log.error("Error happens during post boot: %s", e)
        raise

    return 0

if __name__ == '__main__':
  start_time = time.time()
  main()
  log.info("--- Finished in %.4f seconds ---", (time.time() - start_time))

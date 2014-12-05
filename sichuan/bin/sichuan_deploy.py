#!/usr/bin/env python
#
# Copyright 2014, Leon's Workshop Ltd, All rights reserved.
#

import sys
import argparse
import os
import socket
import time
import yaml

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
    parser.add_argument('--pbt',
                        default='/opt/shoowo/skeleton/xmt/phase_build.yaml',
                        help="Phase build table file path")
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


def load_yaml(yaml_path):
    """
    Load yaml file into python dict (key is phase number)
    """
    try:
        with open(yaml_path, 'r') as yamlfile:
            yaml_data = dict(map(lambda x: (x['phase'], x), yaml.load_all(yamlfile)))
    except yaml.YAMLError as ex:
        if hasattr(ex, 'problem_mark'):
            mark = ex.problem_mark
            log.error("YAML load error at position (%s:%s)",
                    mark.line + 1, mark.column + 1)

    return yaml_data


def deploy_build(pmt_entry, pbt):
    """
    Deploy the build specified in pbt table
    """
    host = pmt_entry['host']
    phase = pmt_entry['phase']

    log.info(" == start deploying the build for host %s at phase %s", host, phase)

    # checkout the branch
    d_branch = pbt[phase]['branch']
    utils.run_command("git checkout " + d_branch)

    # if tag is speicifed, checkout that tag
    if 'tag' in pbt[phase]:
        utils.run_command("git reset --hard " + pbt[phase]['tag'])
        log.info(" -- deployed the build at TAG %s", pbt[phase]['tag'])
    else:
        utils.run_command('git pull')
        log.info(" -- deployed the lastest build")


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

        # start deployment with the specified build
        pbt = load_yaml(args.pbt)
        deploy_build(pmt_entry, pbt)

    except Exception as e:
        log.error("Error happens during post boot: %s", e)
        raise

    return 0

if __name__ == '__main__':
  start_time = time.time()
  main()
  log.info("--- Finished in %.4f seconds ---", (time.time() - start_time))

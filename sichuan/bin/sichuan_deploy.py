#!/usr/bin/env python
#
# Copyright 2014, Logstream Ltd, All rights reserved.
#
# This tool is used as a cron job on all logstream servers to
#   - continuously (regularly) pull BMT/PMT info from the
#     logstream-cd server and pull the new build binaries
#     from the OSS
#   - deploy the build bits on the local server via hiera
#   - report the deploy status
#

import sys
import argparse
import os
import glob
import socket
import yaml
import time

sys.path.append('.')

from pylib.common import exception as exp
from pylib.common import utils
from pylib.common import log
from pylib.framework.lib import xmt

"""
Global options
"""
opts = {}


def parseArguments():
  parser = argparse.ArgumentParser(description="logstream build deployment tool")
  parser.add_argument('--verbose', action='store_true',
                      required=False,
                      help="Print out more debugging information")
  parser.add_argument('--console',
                      required=False, action='store_true',
                      help="Print out log to console")
  parser.add_argument('--logfile', default='/var/log/logstream/sichuan_deploy.log',
                      help="Logging file")
  parser.add_argument('--home', default='/home/logstream',
                      help="Home directory of logstream code")
  parser.add_argument('--package_dir', '-p',
                      default='/opt/logstream/package',
                      help="Root directory for logstream package")
  parser.add_argument('--work', '-w',
                      default='/opt/logstream/deploy',
                      help="Working directory for this tool")
  parser.add_argument('--force', '-f',
                      required=False, action='store_true',
                      help="Flag to force upgrade the build")
  parser.add_argument('--pmt',
                      default='/opt/logstream/sites/xmt/pmt.yaml',
                      help="Phase mapping table file path")
  parser.add_argument('--bmt',
                      default='/opt/logstream/sites/xmt/bmt.yaml',
                      help="Build Bits mapping table file path")
  args = parser.parse_args()
  return args


def prepare():
  args = parseArguments()
  if not os.path.exists(args.home):
    log.error("Error: directory %s not exists", args.home)
    raise exp.InvalidConfigurationOption(opt_name='home', opt_value=args.home)

  if not os.path.exists(args.package_dir):
    log.info("Create package dir %s", args.package_dir)
    os.makedirs(args.package_dir)

  if not os.path.exists(args.work):
    log.info("create working dir %s", args.work)
    os.mkdir(args.work)

  if not os.path.isfile(args.pmt):
    log.error("Error: file %s not exists", args.pmt)
    raise exp.InvalidConfigurationOption(opt_name='pmt', opt_value=args.pmt)

  if not os.path.isfile(args.bmt):
    log.error("Error: file %s not exists", args.bmt)
    raise exp.InvalidConfigurationOption(opt_name='bmt', opt_value=args.bmt)

  opts['home'] = args.home
  opts['work'] = args.work
  opts['pkg'] = args.package_dir
  opts['force'] = args.force
  opts['pmt'] = args.pmt
  opts['bmt'] = args.bmt
  opts['verbose'] = args.verbose
  opts['logfile'] = args.logfile
  opts['console'] = args.console
  opts['hostname'] = socket.gethostname()

  log.init_logging(opts)

  return opts


def deploy_build(pmt_entry, bmt_entry):
  """
  Deploy the build bits specified in BMT table by downloading
  the bits from OSS
  """
  log.info("Start deploying the specified build bits: %s", bmt_entry['build_url'])

  # get the last deployment state
  deploy_state_file = opts['work'] + '/' + 'deploy_state.yaml'
  deploy_state = {}
  try:
    if os.path.isfile(deploy_state_file):
      with open(deploy_state_file, 'r') as state_file:
        deploy_state = yaml.load(state_file)
  except yaml.YAMLError as ex:
    if hasattr(ex, 'problem_mark'):
      mark = ex.problem_mark
      log.error("YAML (%s) load error at position (%s:%s)", (deploy_state_file,
                mark.line + 1, mark.column + 1))
    raise

  build_url = bmt_entry['build_url']
  if not opts['force']:
    if 'build_url' in deploy_state and \
       deploy_state['build_url'] == build_url:
      log.info("Build number is unchanged. Skip downloading this build.")
      return 1

  build_number = build_url.split('/')[-1]
  lgs_yaml_dir = opts['home'] + '/sites/hiera/' + pmt_entry['environment']
  lgs_build_yaml = lgs_yaml_dir + '/' + 'logstream-build.yaml'
  lgs_build = {'logstream_package_dir': opts['pkg'],
               'logstream_build': build_number
               }
  try:
    with open(lgs_build_yaml, 'w') as build_yaml_file:
      yaml.dump(lgs_build, build_yaml_file, default_flow_style=False)
  except yaml.YAMLError as ex:
    log.error("YAML (%s) dump error: %s", (lgs_build_yaml, ex))
    raise

  # purge the old build bits
  files = glob.glob(opts['pkg'] + '/*.deb')
  for filename in files:
    os.unlink(filename)

  # download the build bits from the OSS
  cmd = "osscmd downloadtodir " + build_url + " " + opts['pkg']
  utils.run_command(cmd)

  log.info("Successfully download the logstream build %s", build_number)
  deploy_state['build_url'] = build_url

  try:
    with open(deploy_state_file, 'w') as deploy_file:
      yaml.dump(deploy_state, deploy_file, default_flow_style=False)
  except yaml.YAMLError as ex:
    log.error("YAML (%s) dump error: %s", (deploy_file, ex))
    raise

  return 0


def main():
  try:
    # prepare the working environment
    prepare()

    # load PMT/BMT table
    xmt_mgr = xmt.XmtManager()
    xmt_mgr.load(xmt.XMT_TYPE_PMT, opts['pmt'])
    xmt_mgr.load(xmt.XMT_TYPE_BMT, opts['bmt'])

    pmt_entry = xmt_mgr.get_entry(xmt.XMT_TYPE_PMT, opts['hostname'])
    log.debug("Get the PMT entry: %s", pmt_entry)
    bmt_entry = xmt_mgr.get_entry(xmt.XMT_TYPE_BMT, pmt_entry['phase'])
    log.debug("Get the BMT entry: %s", bmt_entry)

    # update the build from oss
    deploy_build(pmt_entry, bmt_entry)

    # modify puppet config with proper environment value
    cmd = "sed -i \'s/environment=production$/environment=" + \
          pmt_entry['environment'] + "/g\' /etc/puppet/puppet.conf"
    utils.run_command(cmd)

  except Exception as e:
    log.error("Error happens during deployment: %s", e)
    raise

  return 0

if __name__ == '__main__':
  start_time = time.time()
  main()
  log.info("--- Finished in %.4f seconds ---", (time.time() - start_time))

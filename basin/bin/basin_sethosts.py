#!/usr/bin/env python
#
# Copyright 2014, Leon's workshop Ltd, all rights reserved
#
# This tool is used to generate local /etc/hosts and
# set the hostname for the local system
#

import argparse
import os
import sys
import socket
import yaml

sys.path.append('.')

from pylib.common import exception as exp
from pylib.common import log
from pylib.common import utils
from pylib.framework.lib import xmt


def parseArguments():

  parser = argparse.ArgumentParser(description="shoowo set hosts tool")
  parser.add_argument('--verbose', action='store_true',
                      required=False,
                      help="Print out more debugging information")
  parser.add_argument('--console', action='store_true', required=False,
                      help="Print out log to console")
  parser.add_argument('--logfile', default='/var/log/shoowo/misc.log',
                      help="logging file location")
  parser.add_argument('--pmt',
                      default='/opt/shoowo/skeleton/xmt/pmt.yaml',
                      help="Phase mapping table file path")
  parser.add_argument('--boot', action='store_true',
                      required=False,
                      help="Specify if the system is in boot phase")
  parser.add_argument('--ecs_name', required=False,
                      help="ECS ID required in boot mode")
  parser.add_argument('--hosts', default='/etc/hosts',
                      help="hosts file to write to")
  parser.add_argument('--host', default='/opt/shoowo/run/host.yaml',
                      help="host.yaml metadat file to write to")
  parser.add_argument('--template', default='/opt/shoowo/basin/conf/hosts.tpl',
                      help="/etc/hosts template file")

  args = parser.parse_args()
  return args


def prepare():
  args = parseArguments()

  log.init_logging({'verbose': args.verbose,
                    'console': args.console,
                    'logfile': args.logfile})

  if args.boot is True and args.ecs_name is None:
    log.error("ecs_name must be given in boot mode")
    raise exp.InvalidConfigurationOption(opt_name="ecs_name",
                                         opt_val=None)

  if not os.path.isfile(args.pmt):
    log.error("file %s not exists", args.pmt)
    raise exp.InvalidConfigurationOption(opt_name='pmt',
                                         opt_value=args.pmt)

  if not os.path.isfile(args.template):
    log.error("template file %s not exists", args.template)
    raise exp.InvalidConfigurationOption(opt_name='template',
                                         opt_value=args.template)

  return args


def set_hostname(args, xmt_mgr):
  """setup the hostname in boot mode
  """
  try:
    pmt_entries = xmt_mgr.get_entries(xmt.XMT_TYPE_PMT)
    pmt_entry = [x for x in pmt_entries if args.ecs_name.find(x['ecs_name']) != -1][0]
#    pmt_entry = xmt_mgr.get_entries(xmt.XMT_TYPE_PMT, filter={'ecs_name': args.ecs_name})[0]
  except ValueError:
    log.error("Didn't find the host give ecs_name [%s]!", args.ecs_name)
    raise

  hostname = pmt_entry['host']
  cmd = "echo " + hostname + " > /etc/hostname"
  utils.run_command(cmd)
  utils.run_command('hostname ' + hostname)
  log.info("set hostname to [%s]", hostname)


def read_hosts(xmt_mgr):
  """Read host entries from pmt table and
  convert to the list of host alias
  """
  lines = []
  for pmt_entry in xmt_mgr.get_entries(xmt.XMT_TYPE_PMT):
    hostname = pmt_entry['host']
    if 'ip_fqdns' in pmt_entry:
      for ip_entry in pmt_entry['ip_fqdns']:
        lines.append(ip_entry['ip'] + " " + hostname + "\n")
        if 'aliases' in ip_entry:
          for alias in ip_entry['aliases']:
            lines.append(ip_entry['ip'] + " " + alias + "\n")
  return lines


def set_hosts(args, xmt_mgr):
  """Set /etc/hosts for host/ip mapping on
     the local host
  """
  log.info("refresh hosts file [%s]", args.hosts)
  with open(args.template, 'r') as tplfile:
    contents = tplfile.readlines()
    contents += read_hosts(xmt_mgr)
    with open(args.hosts, 'w') as hostsfile:
      hostsfile.writelines(contents)


def set_host_meta(args, xmt_mgr):
  hostname = socket.gethostname()
  try:
    pmt_entry = xmt_mgr.get_entry(xmt.XMT_TYPE_PMT, hostname)
    with open(args.host, 'w') as host_file:
        yaml.dump(pmt_entry, host_file, explicit_start=True,
                default_flow_style=False)
  except KeyError:
    log.info("No %s defined in the PMT", hostname)


def main():
  try:
    args = prepare()

    xmt_mgr = xmt.XmtManager(pmt_path=args.pmt)
    xmt_mgr.load(xmt.XMT_TYPE_PMT)

    if args.boot is True:
      set_hostname(args, xmt_mgr)

    set_hosts(args, xmt_mgr)
    set_host_meta(args, xmt_mgr)
  except exp.ShucaibaoException as e:
    log.error("Error happens during hosts refreshing: %s", e.message)
    raise e
  return 0


if __name__ == "__main__":
  main()

#!/usr/bin/env python
#
# Copyright 2014, Logstream Ltd, All rights reserved.
#
# This tool is used as a cron job to get all ECS status
# from aliyun platform and output to given log file in
# JSON format.
#

# TODO:
# Usage:
# python sichuan_ecs_monitor.py --console --logfile logfile
#   --id aliyun_access_id --key aliyun_access_key
#

import sys
import argparse
import time
import json

sys.path.append('.')
sys.path.append('pylib/vendors')


from pylib.vendors import aliyun
from pylib.common import log

"""
Global options
"""
opts = None


def parseArguments():
  parser = argparse.ArgumentParser(description="logstream ecs monitor tool")
  parser.add_argument('--verbose', action='store_true',
                      required=False,
                      help="Print out more debugging information")
  parser.add_argument('--console',
                      required=False, action='store_true',
                      help="Print out log to console")
  parser.add_argument('--logfile', default='/var/log/logstream/sichuan_monitor.log',
                      help="Monitor log data")
  parser.add_argument('--tokenid', default='de43ea6c-0cc1-11e4-beca-b2227cce2b54',
                      help="Tokenid (uuid) associated with the ECS monitor data")
  parser.add_argument('--id', required=True,
                      help="Aliyun access id")
  parser.add_argument('--key', required=True,
                      help="Aliyun access key")
  parser.add_argument('--region', default='cn-qingdao',
                      help="Aliyun datacenter region (default cn-qingdao)")
  args = parser.parse_args()
  return args


def prepare():
  args = parseArguments()

  global opts
  opts = {'verbose': args.verbose,
          'logfile': args.logfile,
          'console': args.console,
          'id': args.id,
          'key': args.key,
          'tokenid': args.tokenid,
          'region': args.region
          }
  log.init_logging(opts)


def probe_ecs_monitor_data():
  req = aliyun.api.Ecs20130110GetMonitorData()
  appinfo = aliyun.appinfo(opts['id'], opts['key'])
  req.set_app_info(appinfo)
  req.RegionId = opts['region']

  resp = None
  try:
    resp = req.getResponse()
    log.info("response: %s", resp)

    log.debug("Total %d instances", resp[u'TotalCount'])
    with open(opts['logfile'], 'a+') as log_file:
      for inst in resp[u'MonitorData'][u'InstanceMonitorData']:
        inst[u'tokenid'] = opts['tokenid']
        log_file.write(json.dumps(inst)+"\n")
  except Exception as e:
    log.error("failed to probe monitor data: %s, %s", e, resp)
    raise e


def main():
  try:
    prepare()

    # probe all hosts
    probe_ecs_monitor_data()

  except Exception as e:
    log.error("Error happens during ECS monitoring: %s", e)
    raise

if __name__ == '__main__':
  start_time = time.time()
  main()
  log.info("--- Finished in %.4f seconds ---", (time.time() - start_time))

#!/usr/bin/env python
#
# Copyright 2014, Leon's Workshop Ltd, All rights reserved.
#
# This tool is used to send the statistics update to Tarim.
#
# Usage:
# basin_sendstats.py --server ip/host --port port --verbose --console
#   --namespace namespace --metric metric_name --pid pidfile
#   --type [server_state] --value value

import argparse
import os
import socket
import sys
import time
import yaml

from statsd import StatsClient

sys.path.append('.')

from pylib.common import exception as exp
from pylib.common import utils
from pylib.common import log

"""
Global options
"""
statsd_client = None
valid_metrics = [{'name': 'deploy.server.state',
                  'type': 'gauge'
                  },
                 {'name': 'deploy.server.build',
                  'type': 'gauge'
                  },
                 {'name': 'deploy.server.phase',
                  'type': 'gauge'
                  },
                 ]


def parseArguments():
  hostname = socket.gethostname()

  parser = argparse.ArgumentParser(description="Shucaibao stats aggregate tool")
  parser.add_argument('--verbose', action='store_true',
                      required=False,
                      help="Print out more debugging information")
  parser.add_argument('--console',
                      required=False, action='store_true',
                      help="Print out log to console")
  parser.add_argument('--logfile', default='/var/log/shucaibao/stats_update.log',
                      help="Logging file")
  parser.add_argument('--server', default="tarim.internal.shucaibao.com",
                      help="Tarim server ip or domain name")
  parser.add_argument('--port', type=int, default=8125,
                      help="tarim server port to collect stats")
  parser.add_argument('--source', default=hostname,
                      help="statistics source identifier")
  parser.add_argument('--prefix', required=False,
                      help="namespace prefix to source property if given")
  parser.add_argument('--metric', required=True,
                      help="statistic metric name")
  parser.add_argument('--value', required=True,
                      help="value of the metric")
  parser.add_argument('--pid', default="/opt/shucaibao/run/stats.pid",
                      help="Pid file path")

  args = parser.parse_args()
  return args


def validate_metric(metric, value):
  """Validate the metric string and value
  """
  match_items = [x for x in valid_metrics if x['name'] == metric]
  if len(match_items) == 0:
    raise exp.InvalidConfigurationOption(opt_name="metric", opt_value=metric)

  metric_def = match_items[0]
  metric_def['value'] = value
  if metric_def['name'] == 'deploy.server.state':
    # normalize the server.state metric (in case the value is the state file)
    if value.isdigit() is True:
      return 0
    if not os.path.isfile(value):
      raise exp.InvalidConfigurationOption(opt_name="value", opt_value=value)
    try:
      with open(value, 'r') as yamlfile:
        server_state = yaml.load(yamlfile)
        metric_def['value'] = server_state['code']
    except yaml.YAMLError as ex:
      if hasattr(ex, 'problem_mark'):
        mark = ex.problem_mark
        print "YAML load error at position (%s:%s)" % (mark.line + 1,
                                                       mark.column + 1)
      raise
  return metric_def


def prepare():
  args = parseArguments()
  pid = str(os.getpid())
  pidfile = args.pid

  log.init_logging({'verbose': args.verbose,
                    'console': args.console,
                    'logfile': args.logfile})

  if utils.check_pid(pidfile) is True:
    log.error("Pid %s already exists, exiting.", pidfile)
    sys.exit()
  else:
    file(pidfile, 'w').write(pid)

  metric_def = validate_metric(args.metric, args.value)

  # initialize statsdclient
  global statsd_client

  statsd_client = StatsClient(host=args['server'], port=args['port'],
                              prefix=(args['prefix'] + "." + args['source']
                                      if args['prefix'] is not None else args['source']))
  return (args, metric_def)


def send_stats_data(args, metric_name, metric_value, metric_type):
  log.info("%s send metric [%s] with value [%s] to %s:%d",
           args['source'], metric_name, metric_value,
           args['server'], args['port'])
  if metric_type == 'gauge':
    statsd_client.gauge(metric_name, int(metric_value))


def main():
  try:
    (args, metric_def) = prepare()
    send_stats_data(args, metric_def['name'],
                    metric_def['value'], metric_def['type'])
  except exp.ShucaibaoException as e:
    log.error("Error happens during stats aggregation: %s", e.message)
    raise e
  finally:
    if args.pidfile and os.path.exists(args['pidfile']):
      os.unlink(args['pidfile'])

  return 0


if __name__ == '__main__':
  start_time = time.time()
  main()
  log.info("--- Finished in %.4f seconds ---", (time.time() - start_time))

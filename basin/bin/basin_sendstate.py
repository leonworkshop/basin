#!/usr/bin/env python
#
# Copyright 2014, Leon's Workshop Ltd, All rights reserved.
#
# This script is purely used in bootstrap phase to update
# server state to tarim (without any extra dependencies)
#
import argparse
import socket
import sys
import yaml

from statsd import StatsClient


def parseArguments():
  hostname = socket.gethostname()

  parser = argparse.ArgumentParser(description="Shucaibao stats aggregate tool")
  parser.add_argument('--server', default="tarim.internal.shucaibao.com",
                      help="Tarim server ip or domain name")
  parser.add_argument('--port', type=int, default=8125,
                      help="tarim server port to collect stats")
  parser.add_argument('--source', default=hostname,
                      help="statistics source identifier")
  parser.add_argument('--metric', required=True,
                      help="statistic metric name")
  parser.add_argument('--value', required=True,
                      help="yaml file of server state")

  args = parser.parse_args()
  return args


def main():
  args = parseArguments()

  # initialize statsdclient
  global statsd_client
  statsd_client = StatsClient(host=args.server, port=args.port,
                              prefix=args.source)

  value = None
  try:
    with open(args.value, 'r') as yamlfile:
      server_state = yaml.load(yamlfile)
      value = server_state['code']
  except yaml.YAMLError as ex:
    if hasattr(ex, 'problem_mark'):
      mark = ex.problem_mark
      print "YAML load error at position (%s:%s)" % (mark.line + 1,
                                                     mark.column + 1)
    sys.exit(1)

  print "%s sends metric [%s] with value [%s] to %s:%d" % (
        args.source, args.metric, value, args.server,
        args.port)

  statsd_client.gauge(args.metric, int(value))
  return 0

if __name__ == '__main__':
  main()

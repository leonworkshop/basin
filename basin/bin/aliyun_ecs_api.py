#!/usr/bin/env python
#
# Copyright 2014, Leon's workshop Ltd, All rights reserved.
#
# This tool is used to call Aliyun ECS over its API
# and return the formated json output
#
# Usage:
#  aliyun_ecs_api.py --verbose --api api_method_name
#                    --params k1=v1 k2=v2

import argparse
import json
import sys

sys.path.append('.')
sys.path.append('pylib/vendors')

from pylib.common import exception as exp
from pylib.common import log
from pylib.vendors.aliyun.ecs import api


def key_equal_value(param):
  (key, value) = param.split('=')
  if key is None or value is None:
    raise argparse.ArgumentTypeError("invalid key=value param: " + param)
  return param


def parseArguments():
  params = {}

  parser = argparse.ArgumentParser(description="Shucaibao aliyun ecs api tool")
  parser.add_argument('--verbose', action="store_true", required=False,
                      help="print the debug information")
  parser.add_argument('--access_key', required=False, type=str,
                      help="Aliyun ECS access key")
  parser.add_argument('--access_key_secret', required=False, type=str,
                      help="Aliyun ECS access key secret")
  parser.add_argument('--api', required=False, type=str,
                      help="Aliyun ECS api name")
  parser.add_argument('--params', required=False, nargs='+',
                      type=key_equal_value,
                      help="ECS API request parameters in key=value")
  parser.add_argument('--info', required=False, action='store_true',
                      help="Print out the ECS API details")

  args = parser.parse_args()

  if args.api and args.params:
    if args.access_key is None or args.access_key_secret is None:
      log.error("Please specify the access key and secret")
      raise exp.InvalidParameterValue(opt_name="access_key/secret",
                                      opt_value="missing")

  if args.params is not None:
    for param in args.params:
      (k, v) = param.split('=')
      params[k] = v

  return (args, params)


def print_api_info(api_info):
  print "Aliyun ECS API Information:"
  print " method: " + api_info['method']
  print " description: " + api_info['help']
  print " request parameter list: Boolean (indicates required or not)"
  for (k, v) in api_info['parameters'].iteritems():
    print "   %30s: %-10s" % (k, str(v))
  print ""


def print_api_list(api_list):
  print "Available Aliyun ECS API:"
  for api_name in api_list:
    print " %s" % api_name
  print ""


def main():
  (args, params) = parseArguments()

  opts = {'verbose': args.verbose,
          'console': True,
          }
  log.init_logging(opts)

  ecs_api = api.EcsApi(args.access_key, args.access_key_secret)
  if args.info and args.api:
    api_info = ecs_api.get_api_info(args.api)
    print_api_info(api_info)
    return 0

  if args.info:
    api_list = ecs_api.get_available_apis()
    print_api_list(api_list)
    return 0

  method = getattr(ecs_api, args.api)
  if not method:
    log.error("API %s not implemented", args.api)
    raise exp.InvalidParameterValue(opt_name="api", opt_value=method)

  resp = method(**params)
  print "Aliyun ECS API %s results:\n%s" % (args.api, json.dumps(resp,
                                                                 indent=2,
                                                                 sort_keys=True))

  return 0


if __name__ == "__main__":
  main()

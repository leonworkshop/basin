#
# Copyright 2014, Leon's workshop ltd, all rights reserved.
#

import os
import sys
import subprocess

sys.path.append('.')

from pylib.common import log
from pylib.common import exception as exp


def run_command(cmd):
  """
  This method execute the command in another shell process in blocking mode

  raise exception if the command exits with failure
  """
  output = None
  log.debug("Executing command [%s]", cmd)
  try:
    output = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)
  except subprocess.CalledProcessError as ex:
    errmsg = "<errorcode>: %d \n<output>: %s\n" % (ex.returncode, ex.output)
    log.error("Executing command [%s] failed: %s", cmd, errmsg)
    raise exp.CommandFailure(cmd=cmd, error=errmsg)

  return output


def run_commands(cmds):
  """This method executes the batch cmd in sequence.
    It will raise exception if any command failed.
  """
  for cmd in cmds:
    run_command(cmd)


def run_command_silient(cmd):
  """This method executes the command in silient mode which
    ignore any errors
  """
  try:
    run_command(cmd)
  except Exception:
    log.warn("Executing command [%s] failed siliently.", cmd)


def debug_breakpoint():
  # insert a debug breakpoint
  import pdb
  pdb.set_trace()


def check_pid(pidfile):
  if not os.path.isfile(pidfile):
    log.info("pid file %s does not exist.", pidfile)
    return False
  with open(pidfile, 'r') as pidfile_hd:
    pid = int(pidfile_hd.readline())
    try:
      os.kill(pid, 0)
    except OSError:
      log.info("process %d in file %s not exists.", pid, pidfile)
      return False
    else:
      return True

#
# self test
#
if __name__ == "__main__":
  output = run_command('ls -la')
  print "cmd [ls -la] output: \n" + output

  try:
    output = run_command('unknown_cmd')
    print "cmd [unknown_cmd] output: \n" + output
  except exp.CommandFailure as e:
    print e

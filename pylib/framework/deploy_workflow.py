#
# copyright 2014, Leon's workshop ltd, all rights reserved
#
"""
This module drives the jungar (cd side) deployment
workflow
"""
import time

from pylib.common import exception as exp
from pylib.common import log
from pylib.common import utils
from pylib.framework.lib import xmt


STATE_START = 'start'
STATE_DEPLOYING = 'deploying'
STATE_ROLLBACK = 'rollback'
STATE_EXIT = 'exit'


class DeployWorkflow():
  """This class manages the jungar deployment workflow
    and state machine transition.

    TODO: this class also allows to inject hooks for
    tarim integration
  """

  def __init__(self, xmt_mgr, config_opts):
    """
    config_opts contains 'branch'
    """
    self.xmt_mgr = xmt_mgr
    self.opts = config_opts

    mlb_entry = xmt_mgr.get_entries(xmt.XMT_TYPE_MLB)[0]
    self.max_phase = xmt_mgr.get_max_phase_of_entry(xmt.XMT_TYPE_PMT)

    # current_context contains the state data transferred
    # among the state machine transition
    self.current_context = {'state': STATE_START,
                            'mlb_phase': mlb_entry['phase'],
                            'mlb_build_url': mlb_entry['build_url']
                            }

  def run(self):
    """This method is the main loop for deployment
      state machine
    """
    log.info(">== deployment workflow starts.")

    deploy_state = self.current_context['state']
    log.debug("deploy_state: %s", deploy_state)
    try:
      while deploy_state != STATE_EXIT:
        action = DeployWorkflow.deploy_state_machine[deploy_state]
        action(self)
        deploy_state = self.current_context['state']
      # go through "exit" state to complete the state machine
      DeployWorkflow.deploy_state_machine[deploy_state](self)
    except Exception:
      # rollback to the beginning state
      utils.run_command_silient("git reset --hard deploy_start")
    finally:
      utils.run_command_silient("git tag -d deploy_start")
      utils.run_command_silient("git checkout master")

    log.info("<== deployment workflow completed.")

  def deploy_workflow_start(self):
    """Method to perform actions in start state:
      - checkout the deploy branch
      - prepare for deploying state
    """
    log.info("deploy workflow ==> enter [%s] state",
             self.current_context['state'])
    deploy_branch = self.opts['branch']

    cmds = []
    cmds.append("git checkout -B " + deploy_branch)
    cmds.append("git tag -a deploy_start -m \"jungar: start deploy workflow\"")
    cmds.append("git merge master -m \'jungar: merge from master branch\'")
    utils.run_commands(cmds)

    # prepare to move into next state: deploying
    self.current_context['state'] = STATE_DEPLOYING
    self.current_context['bmt_phase'] = 0

    return self.current_context

  def deploy_workflow_deploying(self):
    """Method to perform deploying at given phase
    """
    log.info("deploy workflow ==> enter [%s] state",
             self.current_context['state'])
    bmt_phase = self.current_context['bmt_phase']
    assert self.current_context['mlb_phase'] == -1 or \
        bmt_phase <= self.current_context['mlb_phase']

    # construct BMT table
    bmt_entries = self.xmt_mgr.construct_bmt_entries(bmt_phase)
    self.xmt_mgr.save(xmt.XMT_TYPE_BMT, bmt_entries)
    msg = "deploy: update bmt to phase %d" % (bmt_phase)

    bmt_file = self.xmt_mgr.get_xmt_file(xmt.XMT_TYPE_BMT)
    output = utils.run_command('git status')
    if output.find("nothing to commit") == -1:
      cmds = []
      cmds.append("git add " + bmt_file)
      cmds.append("git commit -m \'" + msg + "\'")
      utils.run_commands(cmds)

    # TODO: interact with Tarim system to ensure the deployment
    # is successfully on the sichuan machines
    time.sleep(self.opts['wait'])

    # prepare to move into next state
    if self.current_context['mlb_phase'] == -1 and bmt_phase < self.max_phase:
      self.current_context['state'] = STATE_DEPLOYING
      self.current_context['bmt_phase'] = bmt_phase + 1
      return self.current_context

    if bmt_phase < self.max_phase and \
       bmt_phase < self.current_context['mlb_phase']:
      self.current_context['state'] = STATE_DEPLOYING
      self.current_context['bmt_phase'] = bmt_phase + 1
      return self.current_context

    self.current_context['state'] = STATE_EXIT
    self.current_context['prestate'] = STATE_DEPLOYING
    return self.current_context

  def deploy_workflow_rollback(self):
    """Method to start rollback action.
      When rollback completes, it moves to exit state.
    """
    log.info("deploy workflow ==> enter [%s] state",
             self.current_context['state'])
    # rollback to the beginning state
    utils.run_command_silient("git reset --hard deploy_start")

    log.info("wait for rollback completion...")
    time.sleep(self.opts['wait'] * 5)

    self.current_context['state'] = STATE_EXIT
    self.current_context['prestate'] = STATE_ROLLBACK

  def deploy_workflow_exit(self):
    """Method to complete the deployment workflow and
      update BMT and LSB on master branch accordingly
    """
    log.info("deploy workflow ==> enter [%s] state",
             self.current_context['state'])

    if self.current_context['prestate'] == STATE_ROLLBACK:
      # there is nothing to do if it moves from rollback
      # state to exit state. LSB and BMT is always rolled
      # back
      return

    lsb_file = self.xmt_mgr.get_xmt_file(xmt.XMT_TYPE_LSB)

    # update lsb table
    lsb_entries = self.xmt_mgr.construct_lsb_entries()
    self.xmt_mgr.save(xmt.XMT_TYPE_LSB, lsb_entries)
    msg = "jungar: update lsb on deploy branch"
    cmds = []
    cmds.append("git add " + lsb_file)
    cmds.append("git commit -m \'" + msg + "\'")
    utils.run_commands(cmds)

    # update the lsb and bmt table on master branch
    msg = "deploy: update bmt and lsb at the end of workflow"
    cmds = []
    cmds.append('git checkout master')
    cmds.append('git pull')
    cmds.append('git merge ' + self.opts['branch'] +
                " -m \"jungar: merge lsb and bmt to master\"")
    utils.run_commands(cmds)

    retries = 5
    while retries:
      try:
        utils.run_command("git push origin master")
        break
      except exp.CommandFailure:
        log.warn("Push changes to remote failed. Retry [%d/5]", retries)
        retries -= 1
        time.sleep(5)
    return

#
# Define the deploy_state_machine variable inside
# DeployWorkflow class
#
DeployWorkflow.deploy_state_machine = {
    STATE_START:      DeployWorkflow.deploy_workflow_start,
    STATE_DEPLOYING:  DeployWorkflow.deploy_workflow_deploying,
    STATE_ROLLBACK:   DeployWorkflow.deploy_workflow_rollback,
    STATE_EXIT:       DeployWorkflow.deploy_workflow_exit,
    }

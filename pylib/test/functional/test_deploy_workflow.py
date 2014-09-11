#
# copyright 2014, logstream ltd, all rights reserved
#
"""
Functional test for continuous deployment workflow
and state machine transition
"""

import mock
import os
import sys
import shutil

sys.path.append(".")

from pylib.common import log
from pylib.common import utils
from pylib.framework.lib import xmt
from pylib.framework import deploy_workflow
from pylib.test import base

repo_owner="logstream"
repo_name="gittesting"

TESTFILEDIR="wkf"
lsb_file = os.path.join(base.FILEDIR, TESTFILEDIR, "lsb.yaml")
mlb_file = os.path.join(base.FILEDIR, TESTFILEDIR, "mlb.yaml")
bmt_file = os.path.join(base.FILEDIR, TESTFILEDIR, "bmt.yaml")
pmt_file = os.path.join(base.FILEDIR, TESTFILEDIR, "pmt.yaml")

def create_git_test_repo(root_dir, repo_name):
  git_repo = repo_name + ".git"
  git_dir = os.path.join(root_dir, git_repo)
  os.mkdir(git_dir)
  cmds = []
  cmds.append("cd " + git_dir + ";git init --bare")
  cmds.append("cd " + root_dir + ";git clone " + git_dir + " " + repo_name)
  utils.run_commands(cmds)

  test_dir = os.path.join(root_dir, repo_name)
  os.chdir(test_dir)
  cmds = []
  cmds.append("echo test > testfile")
  cmds.append("git add testfile")
  cmds.append("git commit -m \"first commmit\"")
  cmds.append("git push origin master")
  utils.run_commands(cmds)

def remove_git_test_repo(root_dir, repo_name):
  git_repo = repo_name + ".git"
  git_dir = os.path.join(root_dir, git_repo)
  shutil.rmtree(git_dir)
  test_dir = os.path.join(root_dir, repo_name)
  shutil.rmtree(test_dir)

class TestDeployWorkflow(base.BaseTestCase):
  """Test cases for deploy workflow
  """

  def setUp(self):
    super(TestDeployWorkflow, self).setUp()
    log.info("enter setup")

    self.cur_dir = os.getcwd()

    # clone the gittesting repo and make the recovery tag
    create_git_test_repo('/tmp', 'git_test')
    self.work_dir = "/tmp/git_test"
    os.chdir(self.work_dir)
    cmds = []
    cmds.append("git tag -a test_snapshot -m \"test start snapshot\"")
    cmds.append("git config user.email logstream-ci@outlook.com")
    cmds.append("git config user.name logstream-ci")
    cmds.append("git checkout master")
    utils.run_commands(cmds)

    self.file_dir = os.path.join(self.work_dir)
    shutil.copy(lsb_file, self.file_dir)
    shutil.copy(mlb_file, self.file_dir)
    shutil.copy(pmt_file, self.file_dir)
    shutil.copy(bmt_file, self.file_dir)

    cmds = []
    cmds.append("git add " + self.file_dir + "/*.yaml")
    cmds.append("git commit -m \'add test yaml files\'")
    utils.run_commands(cmds)

    self.pmt_file = os.path.join(self.file_dir, "pmt.yaml")
    self.bmt_file = os.path.join(self.file_dir, "bmt.yaml")
    self.lsb_file = os.path.join(self.file_dir, "lsb.yaml")
    self.mlb_file = os.path.join(self.file_dir, "mlb.yaml")
    self.xmt_mgr = xmt.XmtManager(pmt_path = self.pmt_file,
                                  bmt_path = self.bmt_file,
                                  lsb_path = self.lsb_file,
                                  mlb_path = self.mlb_file)
    self.xmt_mgr.load(xmt.XMT_TYPE_PMT)
    self.xmt_mgr.load(xmt.XMT_TYPE_BMT)
    self.xmt_mgr.load(xmt.XMT_TYPE_LSB)
    self.xmt_mgr.load(xmt.XMT_TYPE_MLB)

  def tearDown(self):
    super(TestDeployWorkflow, self).tearDown()
    # Remove the test yaml files to clean up
    # the test environment on remote gittesting
    # repository
    utils.run_command("git reset --hard test_snapshot")
    os.chdir(self.cur_dir)
    remove_git_test_repo('/tmp', 'git_test')

  def test_deploy_worfkflow(self):
    log.info("Enter test_deploy_workflow")
    opts = { 'branch': 'deploy',
             'wait': 1
           }
    deploy_mgr = deploy_workflow.DeployWorkflow(self.xmt_mgr, opts)
    deploy_mgr.run()

    new_xmt_mgr = xmt.XmtManager(pmt_path = self.pmt_file,
                                 bmt_path = self.bmt_file,
                                 lsb_path = self.lsb_file,
                                 mlb_path = self.mlb_file)
    new_xmt_mgr.load(xmt.XMT_TYPE_PMT)
    new_xmt_mgr.load(xmt.XMT_TYPE_BMT)
    new_xmt_mgr.load(xmt.XMT_TYPE_LSB)
    new_xmt_mgr.load(xmt.XMT_TYPE_MLB)

    # validate that bmt and lsb files are updated successfully
    for i in range(2):
      lsb_entry = new_xmt_mgr.get_entry(xmt.XMT_TYPE_LSB, i)
      self.assertEqual(lsb_entry['build_url'], 'logstream-bits-3')
      bmt_entry = new_xmt_mgr.get_entry(xmt.XMT_TYPE_BMT, i)
      self.assertEqual(bmt_entry['build_url'], 'logstream-bits-3')









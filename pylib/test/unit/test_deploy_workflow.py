#
# Copyright 2014, logstream ltd, all rights reserved.
#
"""Unit test for deployment workflow"""

import mock
import sys

sys.path.append(".")

from pylib.common import utils
from pylib.framework import deploy_workflow
from pylib.framework.lib import xmt
from pylib.test import base


class TestDeployWorkflow(base.BaseTestCase):
  """Test cases for deployment workflow
  """

  def setUp(self):
    super(TestDeployWorkflow, self).setUp()

    utils.run_command = mock.MagicMock()
    utils.run_commands = mock.MagicMock()

  @mock.patch.object(xmt.XmtManager, 'get_entries')
  def test_state_machine(self, mock_get_entries):
    # mock mlb entry
    mock_get_entries.return_value = [{'phase': 2,
                                      'build_url': 'logstream-bits-3'
                                      }
                                     ]

    opts = {'branch': 'deploy', 'wait': 1}
    xmt_mgr = xmt.XmtManager()
    deploy_mgr = deploy_workflow.DeployWorkflow(xmt_mgr, opts)

    self.assertEqual(deploy_mgr.current_context['state'],
                     deploy_workflow.STATE_START)
    deploy_mgr.deploy_workflow_start()
    self.assertEqual(deploy_mgr.current_context['state'],
                     deploy_workflow.STATE_DEPLOYING)

    xmt_mgr.construct_bmt_entries = mock.MagicMock()
    xmt_mgr.save = mock.MagicMock()
    xmt_mgr.get_xmt_file = mock.MagicMock()
    xmt_mgr.get_xmt_file.return_value = "bmt.yaml"
    deploy_mgr.deploy_workflow_deploying()
    self.assertEqual(deploy_mgr.current_context['bmt_phase'], 1)
    self.assertEqual(deploy_mgr.current_context['state'],
                     deploy_workflow.STATE_DEPLOYING)

    deploy_mgr.deploy_workflow_deploying()
    self.assertEqual(deploy_mgr.current_context['bmt_phase'], 2)
    self.assertEqual(deploy_mgr.current_context['state'],
                     deploy_workflow.STATE_DEPLOYING)

    deploy_mgr.deploy_workflow_deploying()
    self.assertEqual(deploy_mgr.current_context['bmt_phase'], 2)
    self.assertEqual(deploy_mgr.current_context['state'],
                     deploy_workflow.STATE_EXIT)

    xmt_mgr.construct_lsb_entries = mock.MagicMock()
    xmt_mgr.save = mock.MagicMock()
    xmt_mgr.get_xmt_file = mock.MagicMock()
    xmt_mgr.get_xmt_file.return_value = "lsb.yaml"
    deploy_mgr.deploy_workflow_exit()
    self.assertEqual(deploy_mgr.current_context['state'],
                     deploy_workflow.STATE_EXIT)
    self.assertEqual(deploy_mgr.current_context['bmt_phase'], 2)
    self.assertEqual(deploy_mgr.current_context['mlb_phase'], 2)

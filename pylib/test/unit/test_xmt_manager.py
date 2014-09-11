#
# Copyright 2014, logstream ltd, all rights reserved.
#

"""Unit test for xmt_manager"""

import os
import sets
import sys

sys.path.append(".")

from pylib.common import log
from pylib.framework.lib import xmt
from pylib.test import base


class TestXmtManager(base.BaseTestCase):

  def setUp(self):
    super(TestXmtManager, self).setUp()

    self.pmt_file = os.path.join(base.FILEDIR, "pmt.yaml")
    self.bmt_file = os.path.join(base.FILEDIR, "bmt.yaml")
    self.lsb_file = os.path.join(base.FILEDIR, "lsb.yaml")
    self.mlb_file = os.path.join(base.FILEDIR, "mlb.yaml")
    self.bmt_file_tmp = os.path.join(base.FILEDIR, "bmt.tmp.yaml")
    self.lsb_file_tmp = os.path.join(base.FILEDIR, "lsb.tmp.yaml")

  def test_pmt(self):
    xmt_mgr = xmt.XmtManager()
    xmt_mgr.load(xmt.XMT_TYPE_PMT, self.pmt_file)
    xmt_entry = xmt_mgr.get_entry(xmt.XMT_TYPE_PMT, "host-10.165.18.216")
    self.assertEqual(self.pmt_file, xmt_mgr.get_xmt_file(xmt.XMT_TYPE_PMT))
    self.assertEqual(xmt_entry['host'], "host-10.165.18.216")
    self.assertEqual(xmt_entry['environment'], "staging")
    self.assertEqual(xmt_entry['phase'], 0)
    self.assertEqual(xmt_entry['ecs_id'], "AY140706145158953c6b")
    self.assertEqual(xmt_entry['ecs_region'], "cn-qingdao")

    max_phase = xmt_mgr.get_max_phase_of_entry(xmt.XMT_TYPE_PMT)
    self.assertEqual(max_phase, 1)

    xmt_entries = xmt_mgr.get_entries(xmt.XMT_TYPE_PMT)
    self.assertEqual(len(xmt_entries), 5)

    filter_kv = { 'phase': 0, 'ecs_id': 'AY140628170450311bdc' }
    xmt_entries = xmt_mgr.get_entries(xmt.XMT_TYPE_PMT, filter=filter_kv)
    self.assertEqual(len(xmt_entries), 1)
    xmt_entry = xmt_entries[0]
    self.assertEqual(xmt_entry['host'], "host-10.163.223.28")
    self.assertEqual(xmt_entry['environment'], "staging")
    self.assertEqual(xmt_entry['phase'], 0)
    self.assertEqual(xmt_entry['ecs_id'], "AY140628170450311bdc")
    self.assertEqual(xmt_entry['ecs_region'], "cn-qingdao")

    xmt_entry = xmt_mgr.get_entry(xmt.XMT_TYPE_PMT, "ALITSI00SLB00001")
    self.assertEqual(xmt_entry['ip_fqdns'][0]['ip'], "10.129.144.232")
    self.assertEqual(xmt_entry['ip_fqdns'][0]['aliases'][0],
                     "vip.tsingtao.westlake.internal.logstream.net")

  def test_bmt(self):
    xmt_mgr = xmt.XmtManager()
    xmt_mgr.load(xmt.XMT_TYPE_BMT, self.bmt_file)
    xmt_entry = xmt_mgr.get_entry(xmt.XMT_TYPE_BMT, 0)
    self.assertEqual(self.bmt_file, xmt_mgr.get_xmt_file(xmt.XMT_TYPE_BMT))
    self.assertEqual(xmt_entry['phase'], 0)
    self.assertEqual(xmt_entry['build_url'],
        'logstream-bits-2')

    xmt_mgr.load(xmt.XMT_TYPE_LSB, self.lsb_file)
    xmt_mgr.load(xmt.XMT_TYPE_MLB, self.mlb_file)

    bmt_entries_old = xmt_mgr.get_entries(xmt.XMT_TYPE_BMT)
    self.assertEqual(len(bmt_entries_old), 4)
    bmt_dict_old = dict(map(lambda x: (x['phase'], x['build_url']),
                          bmt_entries_old))

    bmt_entries_new = xmt_mgr.construct_bmt_entries(bmt_phase=2)
    self.assertEqual(len(bmt_entries_new), 4)
    bmt_dict_new = dict(map(lambda x: (x['phase'], x['build_url']),
                          bmt_entries_new))

    for phase_key in bmt_dict_old.keys():
      self.assertEqual(bmt_dict_old[phase_key], bmt_dict_new[phase_key])

    xmt_mgr.save(xmt.XMT_TYPE_BMT, bmt_entries_new, self.bmt_file_tmp)
    bmt_entries_old = xmt_mgr.get_entries(xmt.XMT_TYPE_BMT)
    self.assertEqual(len(bmt_entries_old), 4)
    bmt_dict_old = dict(map(lambda x: (x['phase'], x['build_url']),
                          bmt_entries_old))
    for phase_key in bmt_dict_old.keys():
      self.assertEqual(bmt_dict_old[phase_key], bmt_dict_new[phase_key])

    os.remove(self.bmt_file_tmp)


  def test_lsb(self):
    xmt_mgr = xmt.XmtManager()
    xmt_mgr.load(xmt.XMT_TYPE_LSB, self.lsb_file)
    self.assertEqual(self.lsb_file, xmt_mgr.get_xmt_file(xmt.XMT_TYPE_LSB))
    xmt_entry = xmt_mgr.get_entry(xmt.XMT_TYPE_LSB, 2)
    self.assertEqual(xmt_entry['phase'], 2)
    self.assertEqual(xmt_entry['build_url'],
        'logstream-bits-1')

    xmt_mgr.load(xmt.XMT_TYPE_MLB, self.mlb_file)

    lsb_entries_new = xmt_mgr.construct_lsb_entries()
    self.assertEqual(len(lsb_entries_new), 4)
    lsb_dict_new = dict(map(lambda x: (x['phase'], x['build_url']),
                          lsb_entries_new))

    xmt_mgr.save(xmt.XMT_TYPE_LSB, lsb_entries_new, self.lsb_file_tmp)
    self.assertEqual(len(xmt_mgr.get_entries(xmt.XMT_TYPE_LSB)), 4)
    xmt_entry = xmt_mgr.get_entry(xmt.XMT_TYPE_LSB, 2)
    self.assertEqual(xmt_entry['phase'], 2)
    self.assertEqual(xmt_entry['build_url'],
        'logstream-bits-2')

    os.remove(self.lsb_file_tmp)


  def test_mlb(self):
    xmt_mgr = xmt.XmtManager()
    xmt_mgr.load(xmt.XMT_TYPE_MLB, self.mlb_file)
    self.assertEqual(self.mlb_file, xmt_mgr.get_xmt_file(xmt.XMT_TYPE_MLB))
    xmt_entry = xmt_mgr.get_entry(xmt.XMT_TYPE_MLB, 2)
    self.assertEqual(xmt_entry['phase'], 2)
    self.assertEqual(xmt_entry['build_url'],
        'logstream-bits-2')







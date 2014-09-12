#
# Copyright 2014, Leon's Workshop ltd, all rights reserved.
#
"""
This module is used to manage PMT/BMT/LSB/MLB table data
"""
import yaml

from pylib.common import exception as exp


class XmtTable():
  """Class for representing XMT table
  """
  def __init__(self, key_name, xmt_path):
    """Load the XMT table into memory
    """
    self.key_name = key_name
    self.xmt_path = xmt_path
    try:
      with open(xmt_path, 'r') as xmtfile:
        self.xmt_dict = dict(map(lambda x: (x[key_name], x), yaml.load_all(xmtfile)))
    except yaml.YAMLError as ex:
      if hasattr(ex, 'problem_mark'):
        mark = ex.problem_mark
        print "YAML load error at position (%s:%s)" % (mark.line + 1,
                                                       mark.column + 1)
      raise

  def len(self):
    return len(self.xmt_dict)

  def __getitem__(self, arg):
    return self.xmt_dict[arg]

  def __contains__(self, arg):
    return self.xmt_dict.__contains__(arg)

  def items(self):
    return self.xmt_dict.items()

  def values(self):
    return self.xmt_dict.values()


XMT_TYPE_PMT = 'pmt'
XMT_TYPE_BMT = 'bmp'
XMT_TYPE_LSB = 'lsb'
XMT_TYPE_MLB = 'mlb'


class XmtManager:
  """Class for basin inventory table management
  """

  def __init__(self, pmt_path=None, bmt_path=None, lsb_path=None, mlb_path=None):
    """Load PMT and bmt table into memory
    """
    self.xmt_tables = {XMT_TYPE_PMT: {'file_path': pmt_path, 'key_name': 'host'},
                       XMT_TYPE_BMT: {'file_path': bmt_path, 'key_name': 'phase'},
                       XMT_TYPE_LSB: {'file_path': lsb_path, 'key_name': 'phase'},
                       XMT_TYPE_MLB: {'file_path': mlb_path, 'key_name': 'phase'},
                       }

  def validate_type(self, xmt_type):
    if xmt_type not in self.xmt_tables.keys():
      raise exp.InvalidParameterValue(key='xmt_type', value=xmt_type)

  def get_xmt_file(self, xmt_type):
    self.validate_type(xmt_type)
    return self.xmt_tables[xmt_type]['file_path']

  def load(self, xmt_type, xmt_path=None):
    """Load XMT table into memory
    """
    self.validate_type(xmt_type)
    key_name = self.xmt_tables[xmt_type]['key_name']
    if self.xmt_tables[xmt_type]['file_path'] is None:
      if xmt_path is None:
        raise EmptyValue(key=xmt_type+"_path", store="xmt_path")
      self.xmt_tables[xmt_type]['file_path'] = xmt_path

    self.xmt_tables[xmt_type]['table'] = \
        XmtTable(key_name,
                 self.xmt_tables[xmt_type]['file_path'])

  def get_entry(self, xmt_type, key_value):
    self.validate_type(xmt_type)
    if self.xmt_tables[xmt_type]['table'] is None:
      raise exp.InvalidParameterValue(key=xmt_type+"_table", value=None)
    return self.xmt_tables[xmt_type]['table'][key_value]

  @staticmethod
  def filter_entry(entry, filter):
    match = True
    for (key, value) in filter.items():
      if key not in entry or entry[key] != value:
        match = False
        break
    return match

  def get_entries(self, xmt_type, filter=None):
    self.validate_type(xmt_type)
    if self.xmt_tables[xmt_type]['table'] is None:
      raise exp.InvalidParameterValue(key=xmt_type+"_table", value=None)
    if filter is None:
      return self.xmt_tables[xmt_type]['table'].values()

    xmt_values = self.xmt_tables[xmt_type]['table'].values()
    return [x for x in xmt_values if XmtManager.filter_entry(x, filter)]

  def construct_bmt_entries(self, bmt_phase):
    """This method constructs the BMT table by LSB and MLB tables.
      It returnes the BMT entries (to write into BMT file)
    """
    mlb_entry = self.get_entries(XMT_TYPE_MLB)[0]
    assert mlb_entry['phase'] == -1 or bmt_phase <= mlb_entry['phase']

    lsb_entries = self.get_entries(XMT_TYPE_LSB)
    bmt_entries = list(lsb_entries)
    for bmt_entry in bmt_entries:
      if bmt_entry['phase'] <= bmt_phase:
        if (mlb_entry['phase'] == -1) or \
           (bmt_entry['phase'] <= mlb_entry['phase']):
          bmt_entry['build_url'] = mlb_entry['build_url']
    return bmt_entries

  def construct_lsb_entries(self):
    """This method constructs the new LSB table to align
      with the MLB table
    """
    mlb_entry = self.get_entries(XMT_TYPE_MLB)[0]
    lsb_entries = self.get_entries(XMT_TYPE_LSB)
    for lsb_entry in lsb_entries:
      if mlb_entry['phase'] == -1 or lsb_entry['phase'] <= mlb_entry['phase']:
        lsb_entry['build_url'] = mlb_entry['build_url']
    return lsb_entries

  def save(self, xmt_type, entries, xmt_path=None):
    """Save XMT table into file
    """
    self.validate_type(xmt_type)
    if xmt_path is not None:
      self.xmt_tables[xmt_type]['file_path'] = xmt_path
    elif self.xmt_tables[xmt_type]['file_path'] is None:
      raise EmptyValue(key=xmt_type+"_path", store="xmt_path")

    with open(self.xmt_tables[xmt_type]['file_path'], 'w') as xmt_file:
      yaml.dump_all(entries, xmt_file, explicit_start=True, default_flow_style=False)

    self.load(xmt_type)

  def get_max_phase_of_entry(self, xmt_type):
    self.validate_type(xmt_type)
    xmt_entries = self.get_entries(xmt_type)
    max_phase = max(entry['phase'] for entry in xmt_entries if 'phase' in entry)
    return max_phase

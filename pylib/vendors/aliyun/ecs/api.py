#
# Copyright 2014, Logstream Ltd, All rights reserved.
#
"""
Aliyun ECS API Access lib
"""

import base64
import hmac
import itertools
import mimetypes
import requests
import sys
import time
import urllib
import uuid
from hashlib import sha1

sys.path.append('.')

from pylib.common import log
from pylib.common import exception as exp


ECS_API_VERSION = "2014-05-26"


def mixStr(pstr):
  if(isinstance(pstr, str)):
    return pstr
  elif(isinstance(pstr, unicode)):
    return pstr.encode('utf-8')
  else:
    return str(pstr)


class FileItem(object):
  def __init__(self, filename=None, content=None):
    self.filename = filename
    self.content = content


class MultiPartForm(object):
  """Accumulate the data to be used when posting a form."""

  def __init__(self):
    self.form_fields = []
    self.files = []
    self.boundary = "PYTHON_SDK_BOUNDARY"
    return

  def get_content_type(self):
    return 'multipart/form-data; boundary=%s' % self.boundary

  def add_field(self, name, value):
    """Add a simple field to the form data."""
    self.form_fields.append((name, str(value)))
    return

  def add_file(self, fieldname, filename, fileHandle, mimetype=None):
    """Add a file to be uploaded."""
    body = fileHandle.read()
    if mimetype is None:
      mimetype = mimetypes.guess_type(filename)[0] or 'application/octet-stream'
    self.files.append((mixStr(fieldname), mixStr(filename),
                       mixStr(mimetype), mixStr(body)))
    return

  def __str__(self):
    """Return a string representing the form data, including attached files."""
    # Build a list of lists, each containing "lines" of the
    # request.  Each part is separated by a boundary string.
    # Once the list is built, return a string where each
    # line is separated by '\r\n'.
    parts = []
    part_boundary = '--' + self.boundary

    # Add the form fields
    parts.extend([part_boundary,
                  'Content-Disposition: form-data; name="%s"' % name,
                  'Content-Type: text/plain; charset=UTF-8',
                  '',
                  value,
                  ] for name, value in self.form_fields
                 )

    # Add the files to upload
    parts.extend([part_boundary,
                  'Content-Disposition: file; name="%s"; filename="%s"' %
                  (field_name, filename),
                  'Content-Type: %s' % content_type,
                  'Content-Transfer-Encoding: binary',
                  '',
                  body,
                  ] for field_name, filename, content_type, body in self.files
                 )

    # Flatten the list and add closing boundary marker,
    # then return CR+LF separated data
    flattened = list(itertools.chain(*parts))
    flattened.append('--' + self.boundary + '--')
    flattened.append('')
    return '\r\n'.join(flattened)


class EcsApiTable():
  """
  This class contains the Aliyun ECS public API description
  """
  api_table = [
    {'method': 'instance_create_instance',
     'help': "Method to create a ECS instance.",
     'parameters': {'Action': 'CreateInstance',
                    'RegionId': True,
                    'ZoneId': False,
                    'ImageId': True,
                    'InstanceType': True,
                    'SecurityGroupId': True,
                    'InstanceName': False,
                    'Description': False,
                    'InternetChargeType': False,
                    'InternetMaxBandwidthIn': False,
                    'InternetMaxBandwidthOut': False,
                    'HostName': False,
                    'Password': False,
                    'SystemDisk.Category': False,
                    'SystemDisk.DiskName': False,
                    'SystemDisk.Description': False,
                    'DataDisk.1.Size': False,
                    'DataDisk.1.Category': False,
                    'DataDisk.1.SnapshotId': False,
                    'DataDisk.1.DiskName': False,
                    'DataDisk.1.Description': False,
                    'DataDisk.1.Device': False,
                    'ClientToken': False,
                    },
     },
    {'method': 'instance_start_instance',
     'help': "Method to start a ECS intance",
     'parameters': {'Action': 'StartInstance',
                    'InstanceId': True,
                    },
     },
    {'method': 'instance_stop_instance',
     'help': "Method to stop a ECS intance",
     'parameters': {'Action': 'StopInstance',
                    'InstanceId': True,
                    'ForceStop': False,
                    },
     },
    {'method': 'instance_reboot_instance',
     'help': "Method to reboot a ECS intance",
     'parameters': {'Action': 'RebootInstance',
                    'InstanceId': True,
                    'ForceStop': False,
                    },
     },
    {'method': 'instance_remove_instance',
     'help': "Method to remove a ECS intance",
     'parameters': {'Action': 'DeleteInstance',
                    'InstanceId': True,
                    },
     },
    {'method': 'instance_get_info',
     'help': "Method to return the ECS instance information.",
     'parameters': {'Action': 'DescribeInstanceAttribute',
                    'InstanceId': True,
                    },
     },
    {'method': 'instance_set_attributes',
     'help': "Method to modify ECS instance attributes (security, hostname etc.)",
     'parameters': {'Action': 'ModifyInstanceAttribute',
                    'InstanceId': True,
                    'InstanceName': False,
                    'Description': False,
                    'Password': False,
                    'HostName': False,
                    },
     },
    {'method': 'instance_get_list',
     'help': "Method to get ECS instance info list",
     'parameters': {'Action': 'DescribeInstanceStatus',
                    'RegionId': True,
                    'ZoneId': False,
                    'PageNumber': False,
                    'PageSize': False,
                    },
     },
    {'method': 'instance_join_securitygroup',
     'help': "Method to add the ECS instance into the securitygroup",
     'parameters': {'Action': 'JoinSecurityGroup',
                    'InstanceId': True,
                    'SecurityGroupId': True,
                    },
     },
    {'method': 'instance_leave_securitygroup',
     'help': "Method to remove the ECS instance out of the securitygroup",
     'parameters': {'Action': 'LeaveSecurityGroup',
                    'InstanceId': True,
                    'SecurityGroupId': True,
                    },
     },

    {'method': 'region_get_region_list',
     'help': "Method to get the list of available regions.",
     'parameters': {'Action': 'DescribeRegions',
                    },
     },
    {'method': 'region_get_zone_list',
     'help': "Method to get the list of available zones of a region.",
     'parameters': {'Action': 'DescribeZones',
                    'RegionId': True,
                    },
     },

  ]

  def __init__(self):
    self.api_dict = dict(map(lambda x: (x['method'], x), EcsApiTable.api_table))

  def validate_api_params(self, method, **params):
    if method.lower() not in self.api_dict:
      log.error("Invalid ECS API method: %s", method)
      raise exp.InvalidParameterValue(opt_name='method',
                                      opt_value=method)

    valid_params = self.api_dict[method.lower()]['parameters']
    for (k, v) in valid_params.iteritems():
      if k == 'Action':
        continue
      if valid_params[k] is True and k not in params:
        log.error("Invalid ECS API parameter: missing parameter %s", k)
        raise exp.InvalidParameterValue(opt_name=k, opt_value="missing")
    params['Action'] = self.get_api_action(method)
    return params

  def get_api_info(self, method):
    if method.lower() not in self.api_dict:
      log.error("Invalid ECS API method: %s", method)
      raise exp.InvalidParameterValue(opt_name='method',
                                      opt_value=method)
    return self.api_dict[method.lower()]

  def get_api_action(self, method):
    if method.lower() not in self.api_dict:
      log.error("Invalid ECS API method: %s", method)
      raise exp.InvalidParameterValue(opt_name='method',
                                      opt_value=method)
    return self.api_dict[method.lower()]['parameters']['Action']

  def get_api_table(self):
    return EcsApiTable.api_table


class EcsApi():
  """
  This class provides the Aliyun ECS API access
  """

  def __init__(self, access_key, access_key_secret, owner="unknown"):
    self.access_key = access_key
    self.access_key_secret = access_key_secret
    self.owner = owner
    self.version = ECS_API_VERSION
    self.url_base = "http://ecs.aliyuncs.com/"
    self.api_table = EcsApiTable()

  def get_available_apis(self, details=False):
    if details is True:
      return self.api_table

    apis = (api['method'] for api in self.api_table.get_api_table())
    return apis

  def get_api_info(self, method):
    return self.api_table.get_api_info(method)

  @staticmethod
  def _get_url_base(url):
    return url.split('{')[0]

  def _request_get(self, url, extra_headers=None, params=None):
      return self._request('get', url, extra_headers, params)

  def _request_put(self, url, extra_headers=None, params=None):
      return self._request('put', url, extra_headers, params)

  def _request_post(self, url, extra_headers=None, params=None):
      return self._request('post', url, extra_headers, params)

  def _request_delete(self, url, extra_headers=None, params=None):
      return self._request('delete', url, extra_headers, params)

  def _request(self, method, url, extra_headers=None, params=None):
    """Fire a HTTPS request to github
    """
    common_headers = {'Content-type': 'applicatin/json',
                      'Cache-Control': 'no-cache',
                      'Connection': 'Keep-Alive',
                      }
    if extra_headers is not None:
      headers = dict(common_headers.items() + extra_headers.items())
    else:
      headers = common_headers

    try:
      request_matrix = {
        'get': (lambda: requests.get(url, headers=headers, params=params)),
        'put': (lambda: requests.put(url, headers=headers, params=params)),
        'post': (lambda: requests.post(url, headers=headers, params=params)),
        'delete': (lambda: requests.delete(url, headers=headers, params=params)),
      }
      r = request_matrix[method]()
      if r.status_code != requests.codes.ok:
        out = r.json()
        e = exp.AliyunEcsException(status_code=r.status_code, code=out['Code'],
                                   host=out['HostId'], message=out['Message'],
                                   requestId=out['RequestId'])
        raise e
      return r
    except requests.exceptions.ConnectionError as e:
      log.error("Github request failed due to connection network problem: %s", e)
      raise e
    except requests.exceptions.HTTPError as e:
      log.error("Github request failed due to invalid HTTP response: %s", e)
      raise e
    except requests.exceptions.Timeout as e:
      log.error("Github request failed due to request times out")
      raise e
    except requests.exceptions.TooManyRedirects as e:
      log.error("Github request failed because the request exceeds the configured " +
                "number of maximum redirections")
      raise e
    except requests.exceptions.RequestException as e:
      log.error("Github request failed due to error %s", e)
      raise e

  @staticmethod
  def percent_encode(encodeStr):
    res = urllib.quote(encodeStr.decode(sys.stdin.encoding).encode('utf8'), '')
    res = res.replace('+', '%20')
    res = res.replace('*', '%2A')
    res = res.replace('/', '%2F')
    res = res.replace('%7E', '~')
    return res

  def sign(self, method, parameters):
    """
    Sign the ECS API calling and return the signature
    """
    sortedParameters = sorted(parameters.items(), key=lambda parameters: parameters[0])

    canonicalizedQueryString = ''
    for (k, v) in sortedParameters:
      canonicalizedQueryString += ('&' + EcsApi.percent_encode(k) +
                                   '=' + EcsApi.percent_encode(v))

    stringToSign = (method.upper() + '&' +
                    EcsApi.percent_encode("/") + '&' +
                    EcsApi.percent_encode(canonicalizedQueryString[1:]))

    h = hmac.new(self.access_key_secret + "&", stringToSign, sha1)
    signature = base64.encodestring(h.digest()).strip()
    return signature

  def getMultipartParas(self):
    return []

  def getTranslateParas(self):
    return {}

  def get_app_parameters(self, **kwargs):
    """Form the applicaiton parameter dict"""
    app_params = {}
    for (k, v) in kwargs.iteritems():
      if (not k.startswith("__") and k not in self.getMultipartParas()
         and v is not None):
        if k.startswith("_"):
          app_params[k[1:]] = v
        else:
          app_params[k] = v

    translate_parameter = self.getTranslateParas()
    for (k, v) in app_params.iteritems():
      if k in translate_parameter:
        app_params[translate_parameter[k]] = app_params[k]
        del app_params[k]

    return app_params

  def api_execution(self, http_method, **kwargs):
    timestamp = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    parameters = {'Format': 'json',
                  'Version': self.version,
                  'SignatureVersion': '1.0',
                  'SignatureMethod': 'HMAC-SHA1',
                  'SignatureNonce': str(uuid.uuid1()),
                  'TimeStamp': timestamp,
                  'AccessKeyId': self.access_key,
                  }
    application_parameters = self.get_app_parameters(**kwargs)
    for key in application_parameters.keys():
      parameters[key] = application_parameters[key]

    signature = self.sign(http_method.upper(), parameters)
    parameters['Signature'] = signature

    resp = self._request_get(self.url_base, params=parameters)
    resp_json = resp.json()
    return resp_json

  def instance_get_info(self, **kwargs):
    """Return the information of ECS instance
    """
    params = self.api_table.validate_api_params('instance_get_info', **kwargs)
    return self.api_execution('GET', **params)

  def instance_set_attributes(self, **kwargs):
    """
    This method changes the instance properties including password, name, security etc.
    """
    params = self.api_table.validate_api_params('instance_set_attributes', **kwargs)
    return self.api_execution('GET', **params)

  def instance_create_instance(self, **kwargs):
    """
    This method creates the ECS VM instance
    """
    params = self.api_table.validate_api_params('instance_create_instance', **kwargs)
    return self.api_execution('GET', **params)

  def instance_start_instance(self, **kwargs):
    """
    This method starts the ECS VM instance
    """
    params = self.api_table.validate_api_params('instance_start_instance', **kwargs)
    return self.api_execution('GET', **params)

  def instance_stop_instance(self, **kwargs):
    """
    This method stops the ECS VM instance
    """
    params = self.api_table.validate_api_params('instance_stop_instance', **kwargs)
    return self.api_execution('GET', **params)

  def instance_reboot_instance(self, **kwargs):
    """
    This method reboots the ECS VM instance
    """
    params = self.api_table.validate_api_params('instance_reboot_instance', **kwargs)
    return self.api_execution('GET', **params)

  def instance_remove_instance(self, **kwargs):
    """
    This method removes the ECS VM instance
    """
    params = self.api_table.validate_api_params('instance_remove_instance', **kwargs)
    return self.api_execution('GET', **params)

  def instance_get_list(self, **kwargs):
    """Return the information of ECS instance list
    """
    params = self.api_table.validate_api_params('instance_get_list', **kwargs)
    return self.api_execution('GET', **params)

  def instance_join_securitygroup(self, **kwargs):
    """Move the instance into the securitygroup
    """
    params = self.api_table.validate_api_params('instance_join_securitygroup', **kwargs)
    return self.api_execution('GET', **params)

  def instance_leave_securitygroup(self, **kwargs):
    """Move the instance outof the securitygroup
    """
    params = self.api_table.validate_api_params('instance_leave_securitygroup', **kwargs)
    return self.api_execution('GET', **params)

  def region_get_region_list(self, **kwargs):
    """
    This method returns the available region list
    """
    params = self.api_table.validate_api_params('region_get_region_list', **kwargs)
    return self.api_execution('GET', **params)

  def region_get_zone_list(self, **kwargs):
    """
    This method returns the available zones within a region
    """
    params = self.api_table.validate_api_params('region_get_zone_list', **kwargs)
    return self.api_execution('GET', **params)

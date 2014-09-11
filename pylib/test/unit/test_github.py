#
# Copyright 2014, logstream ltd, all rights reserved.
#

"""Unit test for Github Lib"""

import base64
import mock
import os.path
import sys
import requests

sys.path.append(".")

from pylib.common import log
from pylib.common import github
from pylib.test import base

repo_owner="logstream"
repo_name="ci"
repo_org_url="https://api.github.com/orgs/logstream/repos"
contents_url_base="https://api.github.com/repos/logstream/ci/contents/"
testfilepath="pathto/testfile"


class responseObj():
  """Fake the response object
  """

  def __init__(self, code, resp):
    self.status_code = code
    self.resp = resp

  def json(self):
    return self.resp


def requests_get_side_effect(*args, **kwargs):
  if args[0] == contents_url_base + testfilepath:
    contents = base64.b64encode("hello world")
    resp = { "type": "file",
             "encoding": "base64",
             "name": "testfile",
             "path": testfilepath,
             "content": contents,
             "sha": "1234567890"
           }
    resp_obj = responseObj(requests.codes.ok, resp)
  elif args[0] ==  repo_org_url:
    resp =  [{"name": repo_name,
             "full_name": repo_owner + "/" + repo_name,
             "contents_url": "https://api.github.com/repos/logstream/ci/contents/{+path}"
            }]
    resp_obj = responseObj(requests.codes.ok, resp)
  else:
    raise ValueError("Invalid github request URL: " + args[0])

  return resp_obj


def requests_put_side_effect(*args, **kwargs):
  if args[0] == contents_url_base + testfilepath:
    resp = {"content": {
              "name": "testfile",
              "path": testfilepath,
              "sha": "0987654321",
              "type": 'file',
            },
            "commit": {
              "sha": "1111111111",
            }
          }
    resp_obj = responseObj(requests.codes.ok, resp)

  else:
    raise ValueError("Invalid github request URL: " + args[0])

  return resp_obj


class  TestGithubRepo(base.BaseTestCase):
  """Test cases for GithubRepo class
  """

  def setUp(self):
    super(TestGithubRepo, self).setUp()

    # mock requests methods
    requests.get = mock.MagicMock(side_effect=requests_get_side_effect)
    requests.put = mock.MagicMock(side_effect=requests_put_side_effect)

  def test_githubrepo_object(self):
    githubrepo = github.GithubRepo(token="12345", owner=repo_owner, repo=repo_name)
    self.assertEqual(githubrepo.repo_meta['name'], repo_name)
    self.assertEqual(githubrepo.repo_meta['full_name'],
                     repo_owner + "/" + repo_name)

  def test_get_file_contents(self):
    githubrepo = github.GithubRepo(token="12345", owner=repo_owner, repo=repo_name)
    resp = githubrepo.get_file_contents(owner=repo_owner,
                                        repo=repo_name,
                                        file_path=testfilepath)
    self.assertEqual(resp['contents'], "hello world")
    self.assertEqual(resp['sha'], "1234567890")

  def test_update_file_contents(self):
    githubrepo = github.GithubRepo(token="12345", owner=repo_owner, repo=repo_name)
    resp = githubrepo.update_file_contents(owner=repo_owner,
                                           repo=repo_name,
                                           file_path=testfilepath,
                                           file_contents="hello earth",
                                           sha="000000000",
                                           message="test commit",
                                           branch="jungar")
    self.assertEqual(resp['path'], testfilepath)
    self.assertEqual(resp['sha'], "0987654321")
    self.assertEqual(resp['commit_sha'], "1111111111")





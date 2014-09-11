#
# Copyright 2014, Leon's workshop Ltd, All rights reserved.
#
"""
Github access library
"""

import base64
import json
import os
import requests
import sys

from pylib.common import log


class GithubRepo():
  """This class provides the github repository related APIs
  """

  def __init__(self, token, owner, repo):
    self.token = token
    self.owner = owner
    self.repo = repo
    self.repo_meta = None
    self.committer_name = "shucaibao Basin"
    self.committer_email = "shucaibao.ci@outlook.com"

    # Get the repo metadata
    url = "https://api.github.com/orgs/" + owner + "/repos"
    resp = self._request_get(url)
    for repo_entry in resp.json():
      if repo_entry['full_name'] == owner + "/" + repo:
        self.repo_meta = repo_entry

    if self.repo_meta is None:
      err_msg = "Didn't find the repository: " + owner + "/" + repo
      raise exp.GithubFailure(error=err_msg)


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
    common_headers = {
      'content-type': 'applicatin/json',
      'Authorization': 'token ' + self.token,
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
        r.raise_for_status()
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

  def get_file_contents(self, owner, repo, file_path, ref=None):
    """Return the contents of the specified file in string
    """
    url = GithubRepo._get_url_base(self.repo_meta['contents_url'])
    url += file_path
    log.info("github: get file contents (%s)", url)

    params = {}
    params['ref'] = (None if ref is None else 'master')

    resp = self._request_get(url, params=params)
    resp_json = resp.json()
    file_data = base64.b64decode(resp_json['content'])
    return { 'contents': file_data,
             'sha': resp_json['sha'],
           }

  def update_file_contents(self, owner, repo, file_path,
                          file_contents, message, sha, branch=None):
    """Update the contents of a exisiting file in repo
    """
    url = GithubRepo._get_url_base(self.repo_meta['contents_url'])
    url += file_path
    log.info("github: update file contents (%s)", url)

    params = { 'message': message,
               'path': file_path,
               'content': base64.b64encode(file_contents),
               'sha': sha,
               "committer": {
                 "name": self.committer_name,
                 "email": self.committer_email
               },
               'branch': ('master' if branch is None else branch)
             }
    resp = self._request_put(url, params=params)
    resp_json = resp.json()
    return { 'path': resp_json['content']['path'],
             'sha': resp_json['content']['sha'],
             'commit_sha': resp_json['commit']['sha'],
           }





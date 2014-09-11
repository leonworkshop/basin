# Copyright 2014, Leon's Workshop ltd, all rights reserved

"""
Shucaibao exception definitions
"""

_FATAL_EXCEPTION_FORMAT_ERRORS = False


class ShucaibaoException(Exception):
  """Base Shucaibao exception

    To correctly use this class, inherit from it and define
    a 'message' property. That message will get printf'd
    with the keyword arguments provided to the constructor.
  """
  message = "An unknown exception occurred."

  def __init__(self, **kwargs):
    try:
      super(ShucaibaoException, self).__init__(self.message % kwargs)
      self.msg = self.message % kwargs
    except Exception:
      if _FATAL_EXCEPTION_FORMAT_ERRORS:
        raise
      else:
        # at least get the core message out if something happened
        super(ShucaibaoException, self).__init__(self.message)

  def __str__(self):
    return "ShucaibaoException: %s\nMessage: %s" % (self.__class__.__name__, self.msg)


class InvalidConfigurationOption(ShucaibaoException):
  message = "An invalid value was provided for %(opt_name)s: %(opt_value)s"


class InvalidParameterValue(ShucaibaoException):
  message = "Invalid parameter value: %(key)s=%(value)s"


class EmptyValue(ShucaibaoException):
  message = "The value [%(key)s] does not exists in store: %(store)s"


class CommandFailure(ShucaibaoException):
  message = "Error executing command [%(cmd)s]: \n%(error)s"


class GithubFailure(ShucaibaoException):
  message = "Error in github operation: %(error)s"


class AliyunEcsException(ShucaibaoException):
  message = ("Aliyun ECS error happened. Detailed error message followed.\n" +
             "status_code: %(status_code)d\n" +
             "code: %(code)s\n" +
             "host_id: %(host)s\n" +
             "request_id: %(requestId)s\n" +
             "message: %(message)s\n")

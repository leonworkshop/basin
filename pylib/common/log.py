#
# Copyright 2014, shucaibao Ltd, All rights reserved.
#
"""
Logging module
"""

import logging

module_name = "shucaibao_deploy"


def init_logging(opts):
    format = "%(asctime)s " + module_name + " %(levelname)s: %(message)s"
    log_level = logging.INFO
    if opts['verbose']:
        log_level = logging.DEBUG
    if opts['console']:
        logging.basicConfig(format=format, level=log_level)
    else:
        logging.basicConfig(format=format, filename=opts['logfile'], level=log_level)


def error(msg, *args, **kargs):
    logging.error(msg, *args, **kargs)


def info(msg, *args, **kargs):
    logging.info(msg, *args, **kargs)


def debug(msg, *args, **kargs):
    logging.debug(msg, *args, **kargs)

# == Class shennv::params
#

class shennv::params {
  $root_dir             = '/opt/shennv'
  $config_dir           = '/opt/shennv/shennv_conf'
  $source_dir           = '/opt/shucaibao/shucaibao/projects/meili'
  $mode                 = 'all'  # all, worker, beat
  $start_worker_command        = '/opt/shennv/.venv/bin/meili --config=/opt/shennv/shennv_conf/shennv.conf.py celery worker -l INFO'
  $start_beat_command   = '/opt/shennv/.venv/bin/meili --config=/opt/shennv/shennv_conf/shennv.conf.py celery beat -l INFO'

  $package_name         = 'meili'
  $package_ensure       = 'present'
  $autoupgrade          = false

  $service_autorestart  = true
  $service_enable       = true
  $service_ensure       = 'present'
  $service_name         = 'shennv'
  $service_manage       = true
  $service_startsecs    = 10
  $service_retries      = 99
  $service_stderr_logfile_keep    = 10
  $service_stderr_logfile_maxsize = '20MB'
  $service_stdout_logfile_keep    = 5
  $service_stdout_logfile_maxsize = '20MB'
  $service_stopasgroup    = true
  $service_stopsignal     = 'INT'

  $user_home = '/home/shennv'
  $user_manage = true
  $user_managehome = true
  $user = 'shennv'
  $user_ensure = 'present'
  $group = 'shennv'
  $group_ensure = 'present'

  case $::osfamily {
    'Debian': {}
    default: {
      fail("The ${module_name} module is not supported on ${::osfamily} based system.")
    }
  }

  case $::kernel {
    'Linux': {
      $package_dir = '/opt/shennv/swdl'
    }
    default: {
      fail("\"${module_name}\" provides no config directory default value for \"${::kernel}\"")
    }
  }

  # Download tool

  case $::kernel {
    'Linux': {
      $download_tool = 'wget -O'
    }
    'Darwin': {
      $download_tool = 'curl -o'
    }
    default: {
      fail("\"${module_name}\" provides no download tool default value for \"${::kernel}\"")
    }
  }
}

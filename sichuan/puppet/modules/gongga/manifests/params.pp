# == Class gongga::params
#

class gongga::params {
  $root_dir             = '/opt/gongga'
  $config_dir           = '/opt/gongga/gongga_conf'
  $source_dir           = '/opt/shucaibao/shucaibao/projects/meili'
  $start_command        = '/opt/gongga/.venv/bin/meili --config=/opt/gongga/gongga_conf/gongga.conf.py gongga message'

  $package_name         = 'meili'
  $package_ensure       = 'present'
  $autoupgrade          = false

  $service_autorestart  = true
  $service_enable       = true
  $service_ensure       = 'present'
  $service_name         = 'gongga'
  $service_manage       = true
  $service_startsecs    = 10
  $service_retries      = 99
  $service_stderr_logfile_keep    = 10
  $service_stderr_logfile_maxsize = '20MB'
  $service_stdout_logfile_keep    = 5
  $service_stdout_logfile_maxsize = '20MB'
  $service_stopasgroup    = true
  $service_stopsignal     = 'INT'

  $user_home = '/home/gongga'
  $user_manage = true
  $user_managehome = true
  $user = 'gongga'
  $user_ensure = 'present'
  $group = 'gongga'
  $group_ensure = 'present'

  case $::osfamily {
    'Debian': {}
    default: {
      fail("The ${module_name} module is not supported on ${::osfamily} based system.")
    }
  }

  case $::kernel {
    'Linux': {
      $package_dir = '/opt/gongga/swdl'
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

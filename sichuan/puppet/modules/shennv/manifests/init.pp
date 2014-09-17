# == Class shennv
#
class shennv (
  $version                    = false,

  $redis_host                 = '127.0.0.1',
  $redis_port                 = 6379,
  $rds_host                   = 'rdsejmeynzn3yvu.mysql.rds.aliyuncs.com',
  $rds_port                   = 3306,

  $package_name               = $shennv::params::package_name,
  $package_ensure             = $shennv::params::package_ensure,
  $package_url                = undef,
  $package_url                = $shennv::params::package_url,
  $package_dir                = $shennv::params::package_dir,
  $package_provider           = 'package',
  $package_dl_timeout         = 600,
  $purge_package_dir          = false,
  $autoupgrade                = $shennv::params::autoupgrade,
  $mode                       = $shennv::params::mode,

  $service_autorestart        = hiera('shennv::service_autorestart', $shennv::params::service_autorestart),
  $service_enable             = hiera('shennv::service_enable', $shennv::params::service_enable),
  $service_ensure             = $shennv::params::service_ensure,
  $service_name               = $shennv::params::service_name,
  $service_manage             = $shennv::params::service_manage,
  $service_startsecs          = $shennv::params::service_startsecs,
  $service_retries            = $shennv::params::service_retries,
  $service_stderr_logfile_keep    = $shennv::params::service_stderr_logfile_keep,
  $service_stderr_logfile_maxsize = $shennv::params::service_stderr_logfile_maxsize,
  $service_stdout_logfile_keep    = $shennv::params::service_stdout_logfile_keep,
  $service_stdout_logfile_maxsize = $shennv::params::service_stdout_logfile_maxsize,
  $service_stopasgroup    = hiera('shennv::service_stopasgroup', $shennv::params::service_stopasgroup),
  $service_stopsignal     = $shennv::params::service_stopsignal,

  $group                  = $shennv::params::group,
  $user                   = $shennv::params::user,
  $user_ensure                   = $shennv::params::user_ensure,
  $group_ensure                   = $shennv::params::group_ensure,
  $user_home           = $shennv::params::user_home,
  $user_manage         = hiera('shennv::user_manage', $shennv::params::user_manage),
  $user_managehome     = hiera('shennv::user_managehome', $shennv::params::user_managehome),
) inherits shennv::params {
  # validate parameters
  validate_string($package_name)
  validate_string($package_ensure)
  validate_string($package_url)
  validate_bool($service_autorestart)
  validate_bool($service_enable)
  validate_string($service_ensure)
  validate_string($service_name)

  include '::shennv::users'
  include '::shennv::install'
  include '::shennv::config'
  include '::shennv::service'

  class { 'shennv::package': }

  anchor { 'shennv::begin': }
  anchor { 'shennv::end': }

  Anchor['shennv::begin']
    -> Class['::shennv::package']
    -> Class['::shennv::users']
    -> Class['::shennv::install']
    -> Class['::shennv::config']
    -> Class['::shennv::service']
    -> Anchor['shennv::end']
}
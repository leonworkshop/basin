# == Class gongga
#
class gongga (
  $version                    = false,

  $redis_host                 = '127.0.0.1',
  $redis_port                 = 6379,
  $rds_host                   = 'rdsejmeynzn3yvu.mysql.rds.aliyuncs.com',
  $rds_port                   = 3306,
  $aliyun_access_id           = 'must fill a value',
  $aliyun_access_key          = 'must fill a value',
  $ots_instance_name          = 'EMEIALIHZOTS0001',
  $ots_instance_region        = 'cn-hangzhou',
  $oss_instance_name          = 'alihzoss0001',
  $oss_instance_region        = 'cn-hangzhou',
  $mqs_instance_owner_id      = 'e2x86rc97q',
  $mqs_instance_name          = 'ALIHAMQS0001',
  $mqs_instance_region        = 'cn-hangzhou',

  $package_name               = $gongga::params::package_name,
  $package_ensure             = $gongga::params::package_ensure,
  $package_url                = undef,
  $package_url                = $gongga::params::package_url,
  $package_dir                = $gongga::params::package_dir,
  $package_provider           = 'package',
  $package_dl_timeout         = 600,
  $purge_package_dir          = false,
  $autoupgrade                = $gongga::params::autoupgrade,
  $mode                       = $gongga::params::mode,

  $service_autorestart        = hiera('gongga::service_autorestart', $gongga::params::service_autorestart),
  $service_enable             = hiera('gongga::service_enable', $gongga::params::service_enable),
  $service_ensure             = $gongga::params::service_ensure,
  $service_name               = $gongga::params::service_name,
  $service_manage             = $gongga::params::service_manage,
  $service_startsecs          = $gongga::params::service_startsecs,
  $service_retries            = $gongga::params::service_retries,
  $service_stderr_logfile_keep    = $gongga::params::service_stderr_logfile_keep,
  $service_stderr_logfile_maxsize = $gongga::params::service_stderr_logfile_maxsize,
  $service_stdout_logfile_keep    = $gongga::params::service_stdout_logfile_keep,
  $service_stdout_logfile_maxsize = $gongga::params::service_stdout_logfile_maxsize,
  $service_stopasgroup    = hiera('gongga::service_stopasgroup', $gongga::params::service_stopasgroup),
  $service_stopsignal     = $gongga::params::service_stopsignal,

  $group                  = $gongga::params::group,
  $user                   = $gongga::params::user,
  $user_ensure                   = $gongga::params::user_ensure,
  $group_ensure                   = $gongga::params::group_ensure,
  $user_home           = $gongga::params::user_home,
  $user_manage         = hiera('gongga::user_manage', $gongga::params::user_manage),
  $user_managehome     = hiera('gongga::user_managehome', $gongga::params::user_managehome),
) inherits gongga::params {
  # validate parameters
  validate_string($package_name)
  validate_string($package_ensure)
  validate_string($package_url)
  validate_bool($service_autorestart)
  validate_bool($service_enable)
  validate_string($service_ensure)
  validate_string($service_name)

  include '::gongga::users'
  include '::gongga::install'
  include '::gongga::config'
  include '::gongga::service'

  class { 'gongga::package': }

  anchor { 'gongga::begin': }
  anchor { 'gongga::end': }

  Anchor['gongga::begin']
    -> Class['::gongga::package']
    -> Class['::gongga::users']
    -> Class['::gongga::install']
    -> Class['::gongga::config']
    -> Class['::gongga::service']
    -> Anchor['gongga::end']
}

# == Class meili
#
class meili (
  $version                    = false,
  $package_name               = $meili::params::package_name,
  $package_ensure             = $meili::params::package_ensure,
  $package_url                = undef,
  $package_url                = $meili::params::package_url,
  $package_dir                = $meili::params::package_dir,
  $package_provider           = 'package',
  $package_dl_timeout         = 600,
  $purge_package_dir          = false,
  $autoupgrade                = $meili::params::autoupgrade,

  $service_autorestart        = hiera('meili::service_autorestart', $meili::params::service_autorestart),
  $service_enable             = hiera('meili::service_enable', $meili::params::service_enable),
  $service_ensure             = $meili::params::service_ensure,
  $service_name               = $meili::params::service_name,
  $service_manage             = $meili::params::service_manage,
  $service_startsecs          = $meili::params::service_startsecs,
  $service_retries            = $meili::params::service_retries,
  $service_stderr_logfile_keep    = $meili::params::service_stderr_logfile_keep,
  $service_stderr_logfile_maxsize = $meili::params::service_stderr_logfile_maxsize,
  $service_stdout_logfile_keep    = $meili::params::service_stdout_logfile_keep,
  $service_stdout_logfile_maxsize = $meili::params::service_stdout_logfile_maxsize,
  $service_stopasgroup    = hiera('meili::service_stopasgroup', $meili::params::service_stopasgroup),
  $service_stopsignal     = $meili::params::service_stopsignal,

  $group                  = $meili::params::group,
  $user                   = $meili::params::user,
  $user_ensure                   = $meili::params::user_ensure,
  $group_ensure                   = $meili::params::group_ensure,
  $user_home           = $meili::params::user_home,
  $user_manage         = hiera('meili::user_manage', $meili::params::user_manage),
  $user_managehome     = hiera('meili::user_managehome', $meili::params::user_managehome),
) inherits meili::params {
  # validate parameters
  validate_string($package_name)
  validate_string($package_ensure)
  validate_string($package_url)
  validate_bool($service_autorestart)
  validate_bool($service_enable)
  validate_string($service_ensure)
  validate_string($service_name)

  include '::meili::users'
  include '::meili::install'
  include '::meili::config'
  include '::meili::service'

  class { 'meili::package': }

  anchor { 'meili::begin': }
  anchor { 'meili::end': }

  Anchor['meili::begin']
    -> Class['::meili::package']
    -> Class['::meili::users']
    -> Class['::meili::install']
    -> Class['::meili::config']
    -> Class['::meili::service']
    -> Anchor['meili::end']
}

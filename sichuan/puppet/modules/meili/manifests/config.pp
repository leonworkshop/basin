# == Class meili::config
#

class meili::config inherits meili {
  $tools_path = "$root_dir/tools"

  file { "${config_dir}":
    ensure => directory,
    mode => '0644',
    owner => $user,
    group => $group,
  }

  # initialize the configuration
  file { "${config_dir}/meili.conf.py":
    ensure => "${service_ensure}",
    content => template('meili/meili.conf.py.erb'),
    owner => $user,
    group => $group,
    mode => '0644',
    require => [ File["${config_dir}"] ],
  }
}

# == Class shennv::config
#

class shennv::config inherits shennv {
  $tools_path = "$root_dir/tools"

  file { "${config_dir}":
    ensure => directory,
    mode => '0666',
    owner => $user,
    group => $group,
  }

  # initialize the configuration
  file { "${config_dir}/shennv.conf.py":
    ensure => "${service_ensure}",
    content => template('shennv/shennv.conf.py.erb'),
    owner => $user,
    group => $group,
    mode => '0644',
    require => [ File["${config_dir}"] ],
  }
}

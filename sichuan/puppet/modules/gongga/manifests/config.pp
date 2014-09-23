# == Class gongga::config
#

class gongga::config inherits gongga {
  $tools_path = "$root_dir/tools"

  file { "${config_dir}":
    ensure => directory,
    mode => '0666',
    owner => $user,
    group => $group,
  }

  # initialize the configuration
  file { "${config_dir}/gongga.conf.py":
    ensure => "${service_ensure}",
    content => template('gongga/gongga.conf.py.erb'),
    owner => $user,
    group => $group,
    mode => '0644',
    require => [ File["${config_dir}"] ],
  }
}

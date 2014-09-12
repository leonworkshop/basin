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
    ensure => 'absent'
  }

  exec { 'init_config':
    command => "${tools_path}/with_venv.sh meili init ${config_dir}/meili.conf.py",
    path => ['/bin', '/sbin', '/usr/bin', '/usr/local/bin'],
    cwd => "${root_dir}",
    require => [ File["${config_dir}"], File["${config_dir}/meili.conf.py"] ],
  }

  # syncdb in the first run
  exec { 'meili_syncdb':
    command => "${tools_path}/with_venv.sh meili --config=${config_dir}/meili.conf.py syncdb --noinput",
    path => ['/bin', '/sbin', '/usr/bin', '/usr/local/bin'],
    cwd => "${root_dir}",
    require => Exec['init_config'],
    onlyif => "test ! -f ${root_dir}/first-run"
  }

  # create superuser in the first run
  exec { 'meili_create_superuser':
    command => "${tools_path}/with_venv.sh meili --config=${config_dir}/meili.conf.py createsuperuser --username=admin --email=admin@logstream.net --noinput",
    path => ['/bin', '/sbin', '/usr/bin', '/usr/local/bin'],
    cwd => "${root_dir}",
    require => Exec['meili_syncdb'],
    onlyif => "test ! -f ${root_dir}/first-run"
  }
}

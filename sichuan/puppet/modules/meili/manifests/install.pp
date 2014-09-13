# == Class meili::install
#
# This module perform all installation related procedures for meili

class meili::install inherits meili {
  $tools_path = "${root_dir}/tools"
  $rootdir = "${root_dir}"

  # setup virtualenv
  exec { 'setup-virtualenv':
    command => "python ${tools_path}/install_venv.py",
    path => ['/bin', '/sbin', '/usr/bin'],
  }

  # setup meili cli environment
  exec { 'setup-meili-develop':
    command => "${tools_path}/with_venv.sh python setup.py develop",
    path => ['/bin', '/sbin', '/usr/bin', '/usr/local/bin'],
    cwd => "${root_dir}",
    require => Exec['setup-virtualenv'],
  }

  file { "${tools_path}/with_venv.sh":
    ensure => 'present',
    mode => '775',
  }

  file { "${rootdir}/.venv/bin/meili":
    ensure => 'present',
    mode => '775',
    require => Exec['setup-meili-develop'],
  }

  # create a first-run flag
  file { "${rootdir}/first-run":
    ensure => file,
    content => "If you see this file, you already passed first run.",
  }
}

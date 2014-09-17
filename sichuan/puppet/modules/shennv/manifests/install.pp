# == Class shennv::install
#
# This module perform all installation related procedures for shennv

class shennv::install inherits shennv {
  $tools_path = "${root_dir}/tools"
  $rootdir = "${root_dir}"

  # setup virtualenv
#  python::virtualenv { 'shennv-virtualenv':
#      ensure => present,
#      version => 'system',
#      requirements => '/opt/meili/requirements.txt',
#      venv_dir => '/opt/meili/.venv',
#      cwd => '/opt/meili',
#      owner => "${user}",
#      group => "${group}",
#      timeout => 300
#  }

  # setup shennv cli environment
  exec { 'setup-shennv-develop':
    command => "${tools_path}/with_venv.sh python setup.py develop",
    path => ['/bin', '/sbin', '/usr/bin', '/usr/local/bin'],
    cwd => "${root_dir}",
#    require => Exec['setup-virtualenv'],
#    require => Python::Virtualenv['shennv-virtualenv'],
  }

  file { "shennv-with-venv":
    path => "${tools_path}/with_venv.sh",
    ensure => 'present',
    mode => '775',
  }

  file { "shennv-bin-meili":
    path => "${rootdir}/.venv/bin/meili",
    ensure => 'present',
    mode => '775',
    require => Exec['setup-shennv-develop'],
  }
}

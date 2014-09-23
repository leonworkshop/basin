# == Class gongga::install
#
# This module perform all installation related procedures for gongga

class gongga::install inherits gongga {
  $tools_path = "${root_dir}/tools"
  $rootdir = "${root_dir}"

  # setup virtualenv
#  python::virtualenv { 'gongga-virtualenv':
#      ensure => present,
#      version => 'system',
#      requirements => '/opt/meili/requirements.txt',
#      venv_dir => '/opt/meili/.venv',
#      cwd => '/opt/meili',
#      owner => "${user}",
#      group => "${group}",
#      timeout => 300
#  }

  # setup gongga cli environment
  exec { 'setup-gongga-develop':
    command => "${tools_path}/with_venv.sh python setup.py develop",
    path => ['/bin', '/sbin', '/usr/bin', '/usr/local/bin'],
    cwd => "${root_dir}",
#    require => Exec['setup-virtualenv'],
#    require => Python::Virtualenv['gongga-virtualenv'],
  }

  file { "gongga-with-venv":
    path => "${tools_path}/with_venv.sh",
    ensure => 'present',
    mode => '775',
  }

  file { "gongga-bin-meili":
    path => "${rootdir}/.venv/bin/meili",
    ensure => 'present',
    mode => '775',
    require => Exec['setup-gongga-develop'],
  }
}

# == Class: graphite::install
#
# This class installs graphite packages via pip
#
# === Parameters
#
# None.
#
class graphite::install(
  $django_tagging_ver = '0.3.1',
  $twisted_ver        = '11.1.0',
  $txamqp_ver         = '0.4',
) inherits graphite::params {

  $root_dir = $::graphite::params::root_dir
  $source_dir = "/opt/shucaibao/basin/tarim/graphite"

  exec { "Install graphite-whisper from cloned git source":
    command   => "/opt/graphite/bin/python setup.py install",
    creates   => "/opt/graphite/bin/whisper-create.py",
    cwd       => "/opt/shucaibao/basin/tarim/graphite/whisper",
    logoutput => true,
    path      => ["${root_dir}/bin", "/bin", "/usr/bin", "/usr/sbin"]
  }

  exec { "Install graphite-carbon from cloned git source":
    command   => "/opt/graphite/bin/python setup.py install",
    creates   => "${root_dir}/bin/carbon-aggregator.py",
    cwd       => "/opt/shucaibao/basin/tarim/graphite/carbon",
    logoutput => true,
    path      => ["${root_dir}/bin", "/bin", "/usr/bin", "/usr/sbin"]
  }

  exec { "Install graphite-web from cloned git source":
    command   => "/opt/graphite/bin/python setup.py install",
    creates   => "${root_dir}/webapp/graphite",
    cwd       => "/opt/shucaibao/basin/tarim/graphite/web",
    logoutput => true,
    path      => ["${root_dir}/bin", "/bin", "/usr/bin", "/usr/sbin"]
  }

  if 0 == 1 {
  # FIX IT!

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  Package {
    provider => 'pip',
  }

  # for full functionality we need these packages:
  # madatory: python-cairo, python-django, python-twisted,
  #           python-django-tagging, python-simplejson
  # optinal: python-ldap, python-memcache, memcached, python-sqlite

  # using the pip package provider requires python-pip

  if ! defined(Package[$::graphite::params::python_pip_pkg]) {
    package { $::graphite::params::python_pip_pkg :
      provider => undef, # default to package provider auto-discovery
      before   => [
        Package['django-tagging'],
        Package['twisted'],
        Package['txamqp'],
      ]
    }
  }

  # install python headers and libs for pip

  if ! defined(Package[$::graphite::params::python_dev_pkg]) {
    package { $::graphite::params::python_dev_pkg :
      provider => undef, # default to package provider auto-discovery
      before   => [
        Package['django-tagging'],
        Package['twisted'],
        Package['txamqp'],
      ]
    }
  }

#package { $::graphite::params::graphitepkgs :
#    ensure   => 'installed',
#    provider => undef, # default to package provider auto-discovery
#  }->
  package{'django-tagging':
    ensure   => $django_tagging_ver,
  }->
  package{'twisted':
    name     => 'Twisted',
    ensure   => $twisted_ver,
  }->
  package{'txamqp':
    name     => 'txAMQP',
    ensure   => $txamqp_ver,
  }->
#  package{'graphite-web':
#    ensure   => $::graphite::params::graphiteVersion,
#  }->
#  package{'carbon':
#    ensure   => $::graphite::params::carbonVersion,
#  }->
#  package{'whisper':
#    ensure   => $::graphite::params::whisperVersion,
#  }->

  # workaround for unusual graphite install target:
  # https://github.com/graphite-project/carbon/issues/86
  file { $::graphite::params::carbin_pip_hack_source :
    ensure => link,
    target => $::graphite::params::carbin_pip_hack_target,
  }->
  file { $::graphite::params::gweb_pip_hack_source :
    ensure => link,
    target => $::graphite::params::gweb_pip_hack_target,
  }
  }
}

#
# Copyright 2014, Leon's Workshop Ltd,
# All rights reserved
#

notify {"environment=${environment}": }

hiera_include("classes")

# nginx vhost resource
$nginx_vhosts = hiera('nginx::resource::vhost', {})
create_resources('nginx::resource::vhost', $nginx_vhosts)

# nginx location resources
$nginx_locations = hiera('nginx::resource::location', {})
create_resources('nginx::resource::location', $nginx_locations)

# misc tarim configuration
file { '/alidata1/graphite':
  ensure => directory,
}

file { '/opt/graphite':
  ensure => link,
  target => '/alidata1/graphite",
  require => File['/alidata1/graphite'],
}

file { '/alidata1/log':
  ensure => directory,
  owner => 'root',
  group => 'root',
}

file { '/opt/graphite/webapp/graphite/templates/browserHeader.html':
  ensure   => absent,
  source   => "puppet:///modules/tarim/browserHeader.html",
}

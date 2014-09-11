#
# Copyright 2014, Leon's Workshop Ltd.
# All rights reserved.
#
# Puppet configuration for the datacenter in Aliyun, Qingdao
#
notify {"environment=${environment}": }

hiera_include("classes")

# monitored file log instance resources
$logfile_instances = hiera('rsyslog::imfile', {})
create_resources('rsyslog::imfile', $logfile_instances)

# nginx vhost resource
$nginx_vhosts = hiera('nginx::resource::vhost', {})
create_resources('nginx::resource::vhost', $nginx_vhosts)

# nginx location resources
$nginx_locations = hiera('nginx::resource::location', {})
create_resources('nginx::resource::location', $nginx_locations)

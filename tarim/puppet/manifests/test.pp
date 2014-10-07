
$es_init_config_hash = {
    'ES_USER' => 'elasticsearch',
    'ES_GROUP' => 'elasticsearch',
    'ES_HOME'  => '/opt/elasticserach',
}

class { 'elasticsearch':
    ensure                      => 'present',
    autoupgrade                 => true,
    elasticsearch_user          => 'elasticsearch',
    elasticsearch_group         => 'elasticsearch',
    purge_package_dir           => true,
    init_defaults               => $es_init_config_hash,
    config => { 'cluster.name' => 'tarim.cluster.test' },
    datadir                     => '/alidata1/elasticsearch/data',
    version                     => '1.3.4',
}

elasticsearch::instance { 'es-node-0':
    ensure                      => 'present',
    config => { 'node.name'     => 'tarim.node.test.0' },
}


class { 'graphite':
    gr_max_cache_size           => 256,
    gr_max_updates_per_second   => 200,
    gr_timezone                 => 'Asia/Shanghai',
    gr_line_receiver_interface  => '0.0.0.0',
    gr_line_receiver_port       => 2003,
    gr_enable_udp_listener      => True,
    gr_udp_receiver_interface   => '0.0.0.0',
    gr_udp_receiver_port        => 2003,
    gr_pickle_receiver_interface => '0.0.0.0',
    gr_pickle_receiver_port     => 2004,
    gr_cache_query_interface    => '0.0.0.0',
    gr_cache_query_port         => 7002,
    gr_storage_schemas          => [
        {
            name                => 'carbon',
            pattern             => '^carbon\.',
            retentions          => '1m:90d',
        },
        {
            name                => 'default',
            pattern             => ".*",
            retentions          => "5s:60m,1m:1d,5m:1y",
        }
    ],
    gr_web_server               => 'wsgionly',
    secret_key                  => 'tarim',
}

file { '/alidata1/graphite2':
  ensure => directory,
}

file { '/opt/graphite':
  ensure => link,
  target => '/alidata1/graphite2',
}

file { '/alidata1/log':
  ensure => directory,
  owner => 'root',
  group => 'root',
}

class { 'rsyslog::server':
  enable_tcp  => true,
  enable_udp  => true,
  enable_onefile => false,
  server_dir => '/alidata1/log/',
  custom_config   => undef,
  high_precision_timestamps => false,
  require => File['/alidata1/log']
}

file { '/opt/graphite/webapp/graphite/templates/browserHeader.html':
  ensure   => absent,
  source   => "puppet:///modules/tarim/browserHeader.html",
}

class { 'nginx':
  service_ensure => 'running',
  keepalive_timeout => 0,
  client_body_buffer_size => '150k',
  proxy_send_timeout => '5s',
}


nginx::resource::vhost { 'tarim.shucaibao.com':
    ensure => 'present',
    ssl => true,
    ssl_port => '4433',
    ssl_cert => "/opt/shucaibao/certs/shucaibao.com.crt",
    ssl_key => "/opt/shucaibao/certs/shucaibao.com.key",
    listen_ip => '115.28.40.5',
    listen_port => '4433',
    proxy_set_header => [
        'Host   $http_host',
        'X-Real-IP  $remote_addr',
        'X-Forwarded-For  $proxy_add_x_forwarded_for',
        'X-Forwarded-Proto  $scheme',
    ],
    proxy_redirect => off,
    proxy_read_timeout => '5s',
    client_body_timeout => '5s',
    client_max_body_size => '150k',
    proxy => 'http://unix:/var/run/graphite.sock:/',
}

class { 'statsd':
    graphiteserver   => '0.0.0.0',
    flushinterval    => 10000, # flush every 10 second
    percentthreshold => [75, 90, 99],
    address          => '0.0.0.0',
    listenport       => 8125,
    provider         => npm,
}

class { 'nginx':
  service_ensure => 'running',
  keepalive_timeout => 0,
  client_body_buffer_size => '150k',
  proxy_send_timeout => '5s',
}

nginx::resource::vhost { 'api.shoowo.com':
    ensure => 'present',
    ssl => true,
    ssl_port => '443',
    ssl_cert => "/opt/shoowo/certs/shoowo.com.crt",
    ssl_key => "/opt/shoowo/certs/shoowo.com.key",
    listen_ip => '115.28.40.5',
    listen_port => '8088',
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
    proxy => 'http://127.0.0.1:9000/api/',
}

nginx::resource::location { '/api/':
    ensure => 'present',
    vhost => "api.shoowo.com",
    ssl => true,
    ssl_only => true,
    proxy => 'http://127.0.0.1:9000/api/',
}

nginx::resource::location { '/status':
    ensure => 'present',
    vhost => "api.shoowo.com",
    stub_status => true,
#    location_allow   => ['127.0.0.1'],
#    location_deny    => ['all'],
}

class { 'redis':
    version => '2.8.15',
    redis_port => '6379',
    redis_bind_address => '127.0.0.1',
    redis_max_memory => '2gb',
    redis_loglevel => 'notice',
    redis_user => 'redis',
    redis_group => 'redis',
}

class { '::meili':
  service_ensure => 'present',
  service_enable => true,
  user => 'meili',
  rds_host => 'rdsqbmi7za6bzv2.mysql.rds.aliyuncs.com',
  aliyun_access_id => 'rc7nop4ytXKsi0Kn',
  aliyun_access_key => 'm8UQmEhpnLni9z6G6yAIFNWdT8Sh21',
  ots_instances => [ {'name' => 'EMEIALIHZOTS0002', 'region' =>'cn-hangzhou' } ],
  oss_instances =>[ {'name' => 'leon-oss-test', 'region' => 'cn-hangzhou' },
                    {'name' => 'leon-oss-test', 'region' => 'cn-hangzhou' } ],
  mqs_instance_owner_id =>'e2x86rc97q',
  mqs_instances => [ {'name' => 'ALIHZMQS0002', 'region' =>'cn-hangzhou' }],
  blob_user => 'leon-oss-test',
  blob_public => 'leon-oss-test',
  blob_user_domain => 'leon-oss-test.oss-cn-hangzhou.aliyuncs.com',
  blob_public_domain => 'leon-oss-test.oss-cn-hangzhou.aliyuncs.com',
}


class { '::shennv':
    service_ensure => 'present',
    service_enable => true,
    mode => 'all',
    redis_host => '127.0.0.1',
    redis_port => 6379,
    rds_host => 'rdsqbmi7za6bzv2.mysql.rds.aliyuncs.com',
    aliyun_access_id => 'rc7nop4ytXKsi0Kn',
    aliyun_access_key => 'm8UQmEhpnLni9z6G6yAIFNWdT8Sh21',
    ots_instances => [ {'name' => 'EMEIALIHZOTS0002', 'region' =>'cn-hangzhou' } ],
    oss_instances =>[ {'name' => 'leon-oss-test', 'region' => 'cn-hangzhou' },
                    {'name' => 'leon-oss-test', 'region' => 'cn-hangzhou' } ],
    mqs_instance_owner_id =>'e2x86rc97q',
    mqs_instances => [ {'name' => 'ALIHZMQS0002', 'region' =>'cn-hangzhou' }],
    blob_user => 'leon-oss-test',
    blob_public => 'leon-oss-test',
    blob_user_domain => 'leon-oss-test.oss-cn-hangzhou.aliyuncs.com',
    blob_public_domain => 'leon-oss-test.oss-cn-hangzhou.aliyuncs.com',
}


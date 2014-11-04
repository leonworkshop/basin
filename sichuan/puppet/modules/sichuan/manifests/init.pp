# == Class sichuan
# sichuan class presents the necessary configuration for
# shoowo sichuan servers
#

class sichuan (
  $ip_address = inline_template("<%= @ipaddress %>"),
  $fqdn = inline_template("<%= @fqdn %>"),
  $admin = "root",
  $home_dir = "/opt/shoowo",
  $service_ensure = 'present',
  $admin_pubkey = hiera('sichuan::admin_pubkey', ""),
  ) {

  # Add shoowo server admin public key to ssh authorized keys
  ssh_authorized_key { "admin_pubkey":
    ensure => $service_ensure,
    key => $admin_pubkey,
    user => $admin,
    type => "ssh-rsa",
  }

  # sichuan-apply command
  file { "/usr/local/bin/sichuan-apply":
    ensure => $service_ensure,
    content => template('sichuan/puppet-sichuan-apply.erb'),
    group => $admin,
    owner => $admin,
    mode => '0755',
  }

  # sichuan-update crob job script
  file { "/usr/local/bin/sichuan-update":
    ensure => $service_ensure,
    content => template('sichuan/puppet-sichuan-update.erb'),
    group => $admin,
    owner => $admin,
    mode => '0755',
  }

  # server-state update crob job script
  file { "/usr/local/bin/server-state-update":
    ensure => $service_ensure,
    content => template('sichuan/server-state-update.erb'),
    group => $admin,
    owner => $admin,
    mode => '0755',
  }

  # server-state update crob job script
  file { "/usr/local/bin/hosts-update":
    ensure => $service_ensure,
    content => template('sichuan/hosts-update.erb'),
    group => $admin,
    owner => $admin,
    mode => '0755',
  }

  # cron-job to update server state to tarim
  cron { 'server-state-update':
    ensure => $server_ensure,
    command => "/usr/local/bin/server-state-update",
    user => 'root',
    minute => '*/10',
    require => File['/usr/local/bin/server-state-update'],
  }

  # cron-job to pull basin and skeleton repos
  cron { 'basin-git-pull':
    ensure  => $service_ensure,
    command => "cd $home_dir/basin; git pull",
    user    => 'root',
    minute  => '*/30',
  }

  cron { 'skeleton-git-pull':
    ensure  => $service_ensure,
    command => "cd $home_dir/skeleton; git reset --hard origin/master; git pull",
    user    => 'root',
    minute  => '*/30',
  }

  # The CI git hook to trigger sichuan_apply
#  file { "$home_dir/basin/.git/hooks/post-merge":
#    ensure  => $service_ensure,
#    content => '
#logger Merged new change \$1, do sichuan-apply
#/bin/bash /usr/local/bin/sichuan-apply
#',
#    mode    => '0755',
#    require => File['/usr/local/bin/sichuan-apply']
#  }

  # The basin git hook to trigger sichuan_apply
  file { "$home_dir/skeleton/.git/hooks/post-merge":
    ensure  => $service_ensure,
    content => '
logger Merged new change \$1, do sichuan-apply
/bin/bash /usr/local/bin/sichuan-apply
/bin/bash /usr/local/bin/hosts-update
',
    mode    => '0755',
    require => File['/usr/local/bin/sichuan-apply', '/usr/local/bin/hosts-update']
  }

  # Create logrotate rules
  logrotate::rule { "shoowo":
    ensure => $service_ensure,
    path    => "/var/log/shoowo/*.log",
    rotate  => 10,
    size    => '100k',
    compress => true,
  }
}


# puppet script

# resolvconf service to update resolve.conf
service { 'resolvconf':
  ensure     => running,
  hasrestart => true,
  hasstatus  => true,
}

# Check the resolve configuration
file { '/etc/resolvconf/resolv.conf.d/tail':
  ensure   => present,
  notify   => Service['resolvconf'],
  content  => '
options timeout:1 attempts:1 rotate
nameserver 10.202.72.116
nameserver 8.8.8.8
nameserver 223.5.5.5
'
}

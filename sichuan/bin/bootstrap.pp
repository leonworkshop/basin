#
# Sichuan Puppet bootstrap
#
include git

$jungar_ip_address = "jungar.internal.shucaibao.com"
$home_dir = '/opt/shucaibao'

if $operatingsystem == 'Ubuntu' and $operatingsystemrelease == '14.04' {
  notice("Check data disk for Ubuntu 14.04")

  exec { 'Partition and format /dev/xvdb':
    command => 'sfdisk /dev/xvdb << EOF
,
EOF
mkfs.ext4 /dev/xvdb1',
    creates => '/dev/xvdb1',
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    user    => 'root',
  }

} elsif $operatingsystem == 'Ubuntu' and $operatingsystemrelease == '12.04' {
  notice("Check data disk for Ubuntu 12.04")

  exec { 'Partition and format /dev/xvdb':
    command => '/root/auto_fdisk.sh',
    creates => '/dev/xvdb1',
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    user    => 'root',
  }
}

file { '/alidata1':
  ensure => directory,
} -> mount { '/alidata1':
  ensure => mounted,
  atboot => true,
  device => '/dev/xvdb1',
  fstype =>'ext4',
  options => 'rw',
  require => Exec['Partition and format /dev/xvdb'],
}

git::repo { 'basingit':
  target => "$home_dir/basin",
  source => "logstream@$jungar_ip_address:/opt/shucaibao/basin",
  user => "root",
}

git::repo { 'skeletongit':
  target => "$home_dir/skeleton",
  source => "logstream@$jungar_ip_address:/opt/shucaibao/skeleton",
  user => "root",
}

file { '/usr/bin/osscmd':
  ensure => 'link',
  target =>  "$home_dir/basin/pylib/vendors/aliyun/oss/osscmd",
  mode => '0755',
  require => Git::Repo['basingit']
}

exec { "install_oss_credential":
  command => "osscmd config --host=$oss_host --key=$oss_access_key --id=$oss_access_id",
  cwd => "/usr/bin",
  path => '/usr/bin',
  user => 'root',
  returns => [0, 1],
  require => File['/usr/bin/osscmd'],
}

exec { "python_venv":
  command => "python tools/install_venv.py",
  cwd => "$home_dir/basin",
  user => 'root',
  timeout => '600',
  tries => 2,
  path => '/usr/bin:/usr/local/bin',
  require => Git::Repo['basingit'],
}

# TODO: install certificates for nginx https server
#file { "$home_dir/basin/sichuan/puppet/modules/logstash/files/tuotuo.server.crt":
#  ensure => 'present',
#  source => ['/root/tuotuo.server.crt'],
#  owner => 'root',
#  mode => '0644',
#  require => Git::Repo['basingit'],
#}
#
#file { "$home_dir/basin/sichuan/puppet/modules/logstash/files/tuotuo.server.key":
#  ensure => 'present',
#  source => ['/root/tuotuo.server.key'],
#  owner => 'root',
#  mode => '0644',
#  require => Git::Repo['basingit'],
#}

file { "/etc/puppet/hieradata":
  ensure => 'link',
  target => "$home_dir/skeleton/hiera",
  mode => '0644',
  require => Git::Repo['basingit', 'skeletongit']
}

file { "/etc/puppet/hiera.yaml":
  ensure => 'link',
  target => "$home_dir/basin/sichuan/conf/hiera.yaml",
  mode => '0644',
  require => Git::Repo['basingit'],
}

file { "/etc/hiera.yaml":
  ensure => 'link',
  target => "$home_dir/basin/sichuan/conf/hiera.yaml",
  mode => '0644',
  require => Git::Repo['basingit'],
}

file { "/etc/puppet/puppet.conf":
  ensure => 'present',
  source => ["$home_dir/basin/sichuan/conf/puppet.conf"],
  owner => 'root',
  mode => '0644',
  require => Git::Repo['basingit'],
}

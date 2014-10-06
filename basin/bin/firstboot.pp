#
# Basin Puppet firstboot
# PUPPET script

$ADMIN = 'shucaibao'
$HOME_DIR = '/opt/shucaibao'

############### Setup /alidata1 partition ###############
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

########### python setup ##############
file { '/root/.pip':
  ensure => directory,
}

file { '/root/.pip/pip.conf':
  ensure  => present,
  content => '[global]
index-url = http://pypi.douban.com/simple
',
  require => File['/root/.pip'],
}

class { 'python':
  pip      => true,
  dev      => true,
  virtualenv => true,
  require  => File ['/root/.pip/pip.conf'],
}

# setup python virtual environment
exec { 'setup python virtual environment for CI':
  command  => '/usr/bin/python tools/install_venv.py',
  creates  => "$HOME_DIR/basin/.venv",
  cwd      => "$HOME_DIR/basin",
  user     => 'root',
  require  => Class['python'],
}

############ Github setup ################

include git

file { "/home/$ADMIN/.gitconfig":
  ensure  => present,
  owner   => "$ADMIN",
  content => '
[user]
  name = $github_user
  email = $github_user_email
[core]
  editor = vim',
}

git::repo { "basingit":
  target => "$HOME_DIR/basin",
  source => 'git@github.com:leonworkshop/basin.git',
  user => "$ADMIN",
  require => File["/home/$ADMIN/.gitconfig"],
}

git::repo { "skeletongit":
    target => "$HOME_DIR/skeleton",
    source => "git@github.com:leonworkshop/skeleton.git",
    user => "$ADMIN",
    require => File["/home/$ADMIN/.gitconfig"],
}

# The aliyun osscmd tool symbol link
file { '/usr/bin/osscmd':
  ensure => link,
  target => "${HOME_DIR}/basin/pylib/vendors/aliyun/oss/osscmd",
  require => Git::Repo['basingit'],
}

exec { "install_oss_credential":
  command => "osscmd config --host=$oss_host --key=$oss_access_key --id=$oss_access_id",
  cwd => "/usr/bin",
  path => '/usr/bin',
  user => 'root',
  returns => [0, 1],
  require => File['/usr/bin/osscmd'],
}

# The aliyun osscmd credentials setting
file { "/home/$ADMIN/.osscredentials":
  ensure  => present,
  owner => "$ADMIN",
  group => "$ADMIN",
  content => '[OSSCredentials]
accessid = $oss_access_id
accesskey = $oss_access_key
host = $oss_host
',
  mode    => '0640',
}

file { "/etc/puppet/hieradata":
  ensure => 'link',
  target => "${HOME_DIR}/skeleton/hiera",
  mode => '0644',
  require => Git::Repo['basingit', 'skeletongit']
}

file { ["/etc/puppet/hiera.yaml", "/etc/hiera.yaml"]:
  ensure => 'link',
  target => "${HOME_DIR}/basin/basin/conf/hiera.yaml",
  mode => '0644',
  require => Git::Repo['basingit'],
}

file { "/etc/puppet/puppet.conf":
  ensure => 'present',
  source => ["${HOME_DIR}/basin/basin/conf/puppet.conf"],
  owner => 'root',
  mode => '0644',
  require => Git::Repo['basingit'],
}

file { "/home/$ADMIN/.ssh/id_rsa":
  ensure => present,
  mode   => '600',
}

class { 'nodejs':
  manage_repo => true,
}

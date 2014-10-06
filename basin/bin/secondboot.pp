#
# Basin secondboot puppet script
#

$ADMIN = 'shucaibao'
$HOME_DIR = '/opt/shucaibao'

include git
include sudoers

# shucaibao user
user { "$ADMIN":
  ensure => present,
}

# Add shucaibao as a sudoer
sudoers::allowed_command { "$ADMIN":
  command          => "/usr/bin/puppet, $HOME_DIR/basin/basin/bin/basin_papply.sh",
  user             => "$ADMIN",
  require_password => false,
  comment          => 'Allows access to the service command for the $ADMIN user',
}

# The CI git hook to trigger basin_papply.sh
file { "$HOME_DIR/basin/.git/hooks/post-merge":
  ensure  => present,
  content => '
logger Merged new change \$1, do basin_papply.sh
exec sudo $HOME_DIR/basin/basin/bin/basin_papply.sh -l /var/log/shucaibao/basin_papply
',
  mode    => '755',
}

cron { 'Basin-git-pull':
  ensure  => present,
  command => "cd $HOME_DIR/basin; git pull",
  user    => "$ADMIN",
  minute  => '*/30',
}

cron { 'Skeleton-git-pull':
  ensure  => present,
  command => "cd $HOME_DIR/skeleton; git pull",
  user    => "$ADMIN",
  minute  => '*/30',
}

cron { 'Resolv-check':
  ensure  => present,
  command => "/usr/bin/puppet apply $HOME_DIR/basin/basin/bin/basin_resolv.pp",
  user    => 'root',
  minute  => '*/20',
}


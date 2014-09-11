#!/bin/bash
#
# Copyright 2014, Leon's Workshop Ltd.
# All rights reserved
#

set -e

HOME_DIR=/opt/shucaibao
LOG_DIR=/var/log/shucaibao
STATE_FILE=$HOME_DIR/run/sichuan_state
FIRST_BOOT=sichuan_firstboot.sh

. /root/sichuan_functions

print_msg "============================================"
print_msg ""
print_msg "    Shucaibao Sichuan Bootstrap"
print_msg " "
print_msg "============================================"

state=$(get_system_state)
if [[ $state != "system_bootstrap" ]]; then
  print_msg "This node is already bootstrapped."
  exit 0
fi

print_msg "========== Install the bundles =========="

if [ ! -d $HOME_DIR ]; then
  mkdir -p $HOME_DIR
  mkdir -p $HOME_DIR/run
  cd $HOME_DIR
fi

if [ ! -d $LOG_DIR ]; then
  mkdir -p $LOG_DIR
  chown syslog:syslog $LOG_DIR
fi

apt-get update
apt-get install git openjdk-7-jdk curl htop monit vim-nox supervisor python-pip python-dev build-essential --yes
print_msg "apt-get installation done"

export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# install python virtualenv
run_with_retry "pip install --upgrade pip"
run_with_retry "pip install --upgrade virtualenv"
run_with_retry "pip install --upgrade statsd"
run_with_retry "pip install --upgrade pyyaml"

# Install puppet
pushd $HOME_DIR
run_with_retry "wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb"
dpkg -i puppetlabs-release-precise.deb

apt-get install puppet --yes
print_msg "install puppet"

# Install collectd
# ubuntu 1404 already has collectd 5.4.0
#run_with_retry "wget http://collectd.org/files/collectd-5.4.1.tar.gz"
#tar xvf collectd-5.4.1.tar.gz
#./configure --prefix=/usr --sysconfdir=/etc/collectd --localstatedir=/var --libdir=/usr/lib --mandir=/usr/share/man --enable-all-plugins
#make all install
#print_msg "install collectd"

popd


print_msg "=========== setup /etc/hosts ============="
if [[ $TARIM_IP == '' || $QAIDAM_IP == '' || $JUNGAR_IP == '' ]]; then
  print_msg "No environment settings for TARIM_IP, QAIDAM_IP and JUNGAR_IP. Exiting..."
  exit -1
fi

tarim_ip=${TARIM_IP}
qaidam_ip=${QAIDAM_IP}
jungar_ip=${JUNGAR_IP}
puppet apply --detailed-exitcodes --logdest syslog -e "
  host { 'tarim.internal.shucaibao.net':
    ensure => present,
    ip => '$tarim_ip',
  }
  host { 'qaidam.internal.shucaibao.net':
    ensure => present,
    ip => '$qaidam_ip',
  }
  host { 'jungar.internal.shucaibao.net':
    ensure => present,
    ip => '$jungar_ip',
  }
"

RETVAR=$?
if [[ $RETVAR != 0 && $RETVAR != 2 ]]; then
  system_bad "Failed to add host alias. error code: $RETVAR"
  exit 1
fi

echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config

print_msg "=========== continue bootstrap setup ============="

# setup by puppet
puppet apply -e "
# puppet script

file { '/root/.ssh':
  ensure => 'directory',
  owner  => 'root',
  group  => 'root',
}

# generate root ssh key
exec { 'ssh-keygen -t rsa -P \"\" -f /root/.ssh/id_rsa':
  creates => '/root/.ssh/id_rsa',
  path => '/usr/bin:/usr/local/bin:/bin',
  user => 'root',
}

file { '/$HOME_DIR/run':
  ensure => 'directory',
  owner  => 'root',
  group  => 'root',
}

ssh_authorized_key { 'leon@aliyun-online-dev':
  ensure     => present,
  key        => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDhYS1JYXNOA4VaOXpo5wZg9it2pA8sof4QT7bIU8t71cBCPhj1kaqVhCn/Ffb8fvn6NGQcSbUZUNLJgoM4vXnHpcr6eIYeoEtYIAoLfdaO2J/ydUxS5yawWYjWsKEdhho5hV0+uL5xwZGqLYTcRcTv6YzU2BQOVdvKNAVJJdqCuEtIXlM/W6Gqms9rYyCLqQEUcdxukv5XLl1FcHqZ4O5wYsaGP3/Tv0s6NS525briXDhD1KZdw38G3LHLsGMIGjKfXohfwPmlUB3pXSRWTqKuGHibJaqAD73X2fryqsyVappyBIsuctOR3E4YRiaAYg+55T3+LDRgjU/MTiWmJ+/L',
  type       => 'ssh-rsa',
  user       => 'root',
}

ssh_authorized_key { 'leon@macbook':
    ensure     => present,
    key        => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDFFuQ6fG3d24NHkOmHxPHNLFKda7P5vOQ3trjCSW0WUEnT0CFXkF+UTtU26qYWdoColFFxtzlC+Xjw6g6pclzbhrsFc4CSchrmYwKCTqbrJtyM7nfovwnS+3/GFKuZFw6LYL+GL090gH8q8LdzolGFE8qFO4BessjFUJfcQd1wxI105T8/4ay7MJTjsGMtkGJMgTm7jZPsfCaI8IGIdDs5FYPgWA/6scSxncWZwz8/FNj61cWaYMwsBProssP/93DTzA04/l3ocudwX7TXtSXos3gePUdU91CnYH04Ar0Oejco003cEIwoFqo2D3bjz+4aX2tdwfx2V5C2yv7UQP8d',
    type       => 'ssh-rsa',
    user       => 'root',
}

file { '/etc/rc.local':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  content => '#!/bin/bash -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will exit 0 on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

if [ -x /$HOME_DIR/run/$FIRST_BOOT ]; then
  pushd /$HOME_DIR/run
  eval /bin/bash /$HOME_DIR/run/$FIRST_BOOT
  if [[ $? == 0 ]]; then
    rm /$HOME_DIR/run/$FIRST_BOOT
  fi
  popd
fi

exit 0',
}
"

RETVAR=$?
if [[ $RETVAR != 0 && $RETVAR != 2 ]]; then
  system_bad "Failed to add host alias. error code: $RETVAR"
  exit 1
fi

print_msg "========== update system state =========="

# Move to firstboot state
cat > $STATE_FILE << EOL
---
  state: system_firstboot
  code: 001
EOL
chmod a+r $STATE_FILE
chmod a+w $STATE_FILE
print_msg "system state updated"

print_msg "==================================="
print_msg "Sichuan node bootstrap  finished"
print_msg "==================================="

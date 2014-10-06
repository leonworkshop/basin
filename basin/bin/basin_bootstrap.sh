#!/bin/bash

#
# Copyright 2014, Leon's Workshop ltd, all rights reserved
# This script is used to bootstrap shucaibao CI server
#

. /root/basin_functions

ROOT_DIR=root
HOME_DIR=/opt/shucaibao/
STATE_FILE=$HOME_DIR/run/basin_state
ADMIN=shucaibao

function prompt_notice {
  read -p "$1" yn
}

function get_state {
  if [ ! -f $STATE_FILE ]; then
    echo 'init'
  else
    state=`cat $STATE_FILE | awk '{print substr($0, 8)}'`
    echo $state
  fi
}

echo "============================================"
echo ""
echo "    shucaibao CI Bootstrap"
echo ""
echo "============================================"

echo "----------> Install the bundles <----------"

state=$(get_state)
if [ $state != "init" ]; then
  echo "CI server is already bootstrapped."
  exit 0
fi

# Generate the first boot ready file
#echo "state: in progress" > $STATE_FILE

echo "----------> System setup <-------------"
echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

echo "---------> Install puppet  bundles <---------"
# Install puppet
wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
dpkg -i puppetlabs-release-precise.deb
apt-get update
apt-get install puppet --yes

print_msg "install puppet"

echo "---------> Install apt bundles <---------"
apt-get install git openjdk-7-jdk lpr curl htop monit vim-nox supervisor -y
apt-get install python-cairo maven libffi-dev build-essential python-dev -y
apt-get install python-pip libffi-dev -y

# install python virtualenv
run_with_retry "/usr/local/bin/pip install --upgrade pip"
run_with_retry "/usr/local/bin/pip install --upgrade virtualenv"
run_with_retry "/usr/local/bin/pip install --upgrade statsd"
run_with_retry "/usr/local/bin/pip install --upgrade pyyaml"

print_msg "---------> Install python pip mirror <---------"
if [[ ! -d ~/.pip ]]; then
    mkdir ~/.pip
fi
cat > ~/.pip/pip.conf << EOL
[global]
index-url = http://pypi.douban.com/simple
EOL

# install puppet modules
puppet module install puppetlabs-stdlib
puppet module install steveydevey-htop
puppet module install steveydevey-vim
puppet module install puppetlabs-java
puppet module install ispavailability-file_concat
puppet module install jbussdieker-monit
puppet module install puppetlabs-ntp --version 3.0.3
puppet module install puppetlabs-rsync
puppet module install rodjek-logrotate
puppet module install puppetlabs-apt
puppet module install stankevich-python
puppet module install theforeman-git
puppet module install puppetlabs-nodejs
puppet module install phinze-sudoers
puppet module install saz-rsyslog
print_msg "install puppet modules"

# clean up firstly
puppet apply -e "
  node default {
    # shucaibao admin group
    group { '$ADMIN':
      ensure => absent,
    }

    # shucaibao user
    user { '$ADMIN':
      ensure => absent,
      home => \"/home/$ADMIN\",
    }
  }
"

# setup by puppet
puppet apply -e "
# puppet script

node default {
  # shucaibao admin group
  group { '$ADMIN':
    ensure => present,
  }

  # shucaibao user
  user { '$ADMIN':
    ensure => present,
    home => '/home/$ADMIN',
    shell => '/bin/bash',
  }

  file { '/home/$ADMIN':
    ensure => 'directory',
    owner  => '$ADMIN',
    group  => '$ADMIN',
  }

  file { '/home/$ADMIN/.ssh':
    ensure => 'directory',
    owner  => '$ADMIN',
    group  => '$ADMIN',
  }

  # generate $ADMIN ssh key
  exec { 'ssh-keygen -t rsa -P \"\" -f ~/.ssh/id_rsa':
    creates => '/home/$ADMIN/.ssh/id_rsa',
    path => '/usr/bin:/usr/local/bin:/bin',
    environment => 'HOME=/home/$ADMIN',
    user => '$ADMIN',
  }

  file { '$HOME_DIR':
    ensure => 'directory',
    owner => '$ADMIN',
  }

  file { '$HOME_DIR/run':
    ensure => 'directory',
    owner => '$ADMIN',
  }

  service { 'resolvconf':
    ensure     => running,
    hasrestart => true,
    hasstatus  => true,
  }

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
}

"

echo "---------> Install python bundles <---------"
# Install PyYaml
cd $HOME_DIR
wget http://pyyaml.org/download/pyyaml/PyYAML-3.11.tar.gz
tar xvf PyYAML-3.11.tar.gz
cd PyYAML-3.11
python setup.py install
print_msg "install PyYAML"

echo "------------> Install public key for github access <------------"
pub_key=`cat /home/$ADMIN/.ssh/id_rsa.pub`
echo Upload the pub key into Github...
curl -u $GITHUB_USER -XPOST https://api.github.com/user/keys -d "
{
    \"title\": \"CI-shucaibao-server\",
    \"key\": \"${pub_key}\"
}"

if [[ $? != 0 ]]; then
  echo Add the public key into Github failed
  exit 1
fi

# Move to firstboot state
cat > $STATE_FILE << EOL
---
  state: system_firstboot
  code: 001
EOL
chmod a+w $STATE_FILE
chmod a+r $STATE_FILE

print_msg "Basin system state updated"

echo "==================================="
echo "Shucaibao CI bootstrap finished"
echo "==================================="

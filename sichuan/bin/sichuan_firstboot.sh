#!/bin/bash
#
# Copyright 2014, Leon's Workshop Ltd.
# All rights reserved.
#

HOME_DIR=/opt/shucaibao
JUNGAR_SERVER=jungar.internal.shucaibao.com
STATE_FILE=$HOME_DIR/run/sichuan_state

. /root/sichuan_functions

print_msg "============================================"
print_msg ""
print_msg "    Shucaibao Sichuan Server Machine Firstboot"
print_msg ""
print_msg "============================================"

if [[ $DEBUG != "true" ]]; then
  state=$(get_system_state)
  if [[ $state == "system_bootstrap" ]]; then
    print_msg "Sichuan node bootstrap is not done yet."
    exit 1
  fi
  if [[ $state != "system_firstboot" ]]; then
    print_msg "Sichuan node is not ready for firstboot."
    exit 0
  fi
fi

if [ ! -d $HOME_DIR ]; then
  mkdir -p $HOME_DIR
  mkdir -p $HOME_DIR/run
  cd $HOME_DIR
fi

print_msg "---------> Setup temporary DNS resolver <---------"
cat > /etc/resolv.conf << EOL
options attempts:1 timeout:1 rotate
nameserver 223.5.5.5
nameserver 8.8.8.8
EOL

print_msg "---------> Install python pip mirror <---------"
mkdir ~/.pip
cat > ~/.pip/pip.conf << EOL
[global]
index-url = http://pypi.douban.com/simple
EOL

print_msg "---------> Puppet bootstrap <-----------"

run_with_retry "puppet module install puppetlabs-stdlib"
run_with_retry "puppet module install steveydevey-htop"
run_with_retry "puppet module install steveydevey-vim"
run_with_retry "puppet module install puppetlabs-java"
run_with_retry "puppet module install ispavailability-file_concat"
run_with_retry "puppet module install jbussdieker-monit"
run_with_retry "puppet module install puppetlabs-ntp --version 3.0.3"
run_with_retry "puppet module install puppetlabs-rsync"
run_with_retry "puppet module install theforeman-git"
run_with_retry "puppet module install rodjek-logrotate"
run_with_retry "puppet module install saz-rsyslog"
run_with_retry "puppet module install puppetlabs-concat"
run_with_retry "puppet module install puppetlabs-apt"
print_msg "install puppet modules"

export FACTER_oss_access_id=$OSS_ACCESS_ID
export FACTER_oss_access_key=$OSS_ACCESS_KEY
export FACTER_oss_host=$OSS_HOST

puppet_with_retry "/root/bootstrap.pp"
print_msg "puppet bootstrap is done"

print_msg "----------> Setup basin git repository <----------"
# setup the git (clone from shucaibao-cd server)
cd $HOME_DIR/basin
if [[ $DEBUG != "true" ]]; then
  git checkout master
fi
git pull
git config --global core.editor "vim"
git config --global user.email "shucaibao.ci@outlook.com"
git config --global user.name "Shucaibao Basin"
print_msg "Setup the git repository: shucaibao/basin"

print_msg "----------> Setup skeleton git repository <----------"
# setup the git (clone from shucaibao-cd server)
cd $HOME_DIR/skeleton
if [[ $DEBUG != "true" ]]; then
  git checkout deploy
fi
git pull
git config --global core.editor "vim"
git config --global user.email "shucaibao.ci@outlook.com"
git config --global user.name "shucaibao Basin"
print_msg "Setup the git repository: shucaibao/skeleton"

print_msg "----------> Setup hostname <----------"
cd $HOME_DIR/ci
hostname=`cat /etc/hostname`
tools/with_venv.sh python bin/basin_sethosts.py --verbose --console --boot --ecs_id $hostname --template conf/hosts.tpl
if [ $? -ne 0 ]; then
  system_bad "Failed to add host alias."
  exit 1
fi

if [[ $DEBUG == "true" ]]; then
  tarim_ip=${TARIM_IP}
  qaidam_ip=${QAIDAM_IP}
  jungar_ip=${JUNGAR_IP}
  puppet apply --detailed-exitcodes -e "
    host { 'tarim.internal.shucaibao.com':
      ensure => absent,
    }
    host { 'qaidam.internal.shucaibao.com':
      ensure => absent,
    }
    host { 'jungar.internal.shucaibao.com':
      ensure => absent,
    }
  "
  puppet apply --detailed-exitcodes -e "
    host { 'tarim.internal.shucaibao.com':
      ensure => present,
      ip => '$tarim_ip',
    }
    host { 'qaidam.internal.shucaibao.com':
      ensure => present,
      ip => '$qaidam_ip',
    }
    host { 'jungar.internal.shucaibao.com':
      ensure => present,
      ip => '$jungar_ip',
    }
  "
fi
print_msg "Setup hostname"


# Generate the first boot ready file
system_secondboot

if [[ $DEBUG == 'true' ]]; then
  echo "In DEBUG mode, didn't inovke secondboot!"
  exit 0
fi

# Call the secondboot script
$HOME_DIR/ci/sichuan/bin/sichuan_secondboot.sh



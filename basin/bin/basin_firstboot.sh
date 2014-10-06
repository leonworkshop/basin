#!/bin/bash
#
# Copyright 2014, Leon's Workshop ltd, all rights reserved
#
# This is script is running under root
# to finish the bootstrap things
#

. /root/basin_functions

ROOT_DIR=root
HOME_DIR=/opt/shucaibao
ADMIN=shucaibao

echo "======================================"
echo " Shucaibao Basin bootstrap phase: firstboot"
echo "======================================"

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

if [[ $GITHUB_USER == '' ]]; then
  echo Please set GITHUB_USER and GITHUB_USER_EMAIL environments in /etc/default/locale
  exit 1
fi

pushd $HOME_DIR

export FACTER_oss_access_id=$OSS_ACCESS_ID
export FACTER_oss_access_key=$OSS_ACCESS_KEY
export FACTER_oss_host=$OSS_HOST
export FACTER_github_user=$GITHUB_USER
export FACTER_github_user_email=$GITHUB_USER_EMAIL

puppet_with_retry "/root/firstboot.pp"
print_msg "puppet first bootstrap is done"

print_msg "----------> Setup basin git repository <----------"
cd $HOME_DIR/basin
if [[ $DEBUG != "true" ]]; then
  su $ADMIN -c "git checkout master"
else
  su $ADMIN -c "git checkout sichuan"
fi
git pull
print_msg "Setup the git repository: shucaibao/basin"

print_msg "----------> Setup skeleton git repository <----------"
cd $HOME_DIR/skeleton
if [[ $DEBUG != "true" ]]; then
  su $ADMIN -c "git checkout master"
else
  su $ADMIN -c "git checkout sichuan"
fi
git pull
print_msg "Setup the git repository: shucaibao/skeleton"

print_msg "----------> Setup hostname <----------"
cd $HOME_DIR/basin
hostname=`cat /etc/hostname`
tools/with_venv.sh python basin/bin/basin_sethosts.py --verbose --console --boot --ecs_name $hostname --template basin/conf/hosts.tpl
if [ $? -ne 0 ]; then
  system_bad "Failed to add host alias."
  exit 1
fi
popd

# Generate the first boot ready file
system_secondboot

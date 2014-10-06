#!/bin/bash

#
# Copyright 2014, Leon's Workshop ltd, all rights reserved
#
# This is script is running under root user
# to finish the bootstrap things
#

. /root/basin_functions

ROOT_DIR=root
HOME_DIR=/opt/shucaibao
ADMIN=shucaibao

echo "======================================"
echo " Shucaibao Basin bootstrap phase: secondboot"
echo "======================================"

if [[ $DEBUG != "true" ]]; then
  state=$(get_system_state)
  if [[ $state == "system_bootstrap" ]]; then
    print_msg "basin node bootstrap is not done yet."
    exit 1
  fi

  if [[ $state != "system_secondboot" ]]; then
    print_msg "basin node is not ready for secondboot."
    exit 0
  fi
fi

run_with_retry "apt-get install libffi-dev -y"
run_with_retry "puppet module install puppetlabs-nodejs"
run_with_retry "puppet module install phinze-sudoers"
run_with_retry "puppet module install saz-rsyslog"

wget http://peak.telecommunity.com/dist/ez_setup.py
run_with_retry "python ez_setup.py"

mkdir -p /var/log/shucaibao
chown $ADMIN:$ADMIN /var/log/shucaibao

export FACTER_oss_access_id=$OSS_ACCESS_ID
export FACTER_oss_access_key=$OSS_ACCESS_KEY
export FACTER_oss_host=$OSS_HOST
export FACTER_github_user=$GITHUB_USER
export FACTER_github_user_email=$GITHUB_USER_EMAIL

puppet_with_retry "/root/secondboot.pp"
print_msg "puppet second bootstrap is done"

system_ready "Completed secondboot successfully."

echo "----------> apply the every service puppets <----------"

# Apply the puppet config
exec /bin/bash `dirname $BASH_SOURCE`/basin_papply.sh

#!/bin/bash
#
# Copyright 2014, Leon's Workshop Ltd, All rights reserved.
#
# The entry for setting up the all-in-one CI
#

HOME_DIR=/opt/shucaibao
PAPPLY_CRON='CI-papply'

# Interval to run papply with check, minute
INTERVAL=5

# put all pid file dependences here
PIDFILE=/var/run/papply.pid
PIDFILE_DEP=($PIDFILE $HOME_DIR/run/jungar_deploy.pid)

function is_yield_for_pid_file_dependence {
  for pid_file in "${PIDFILE_DEP[@]}"; do
    if [ -f $pid_file ]; then
      # the pid_file exists
      pid=`cat $PIDFILE`

      if [ -e /proc/$pid ]; then
        echo Another $pid_file is running [`cat $PIDFILE`]
        return 0
      fi
    fi
  done

  return 1
}

if is_yield_for_pid_file_dependence; then
  echo Yield with a postponed cron papply job $PAPPLY_CRON.

  # Add the cron job by puppet
  puppet apply --detailed-exitcodes -e "
    # puppet script
    cron { '$PAPPLY_CRON':
      ensure  => present,
      command => '/bin/bash $HOME_DIR/basin/basin/bin/basin_papply.sh $@',
      user    => 'root',
      minute  => '*/$INTERVAL',
    }"

  exit $?
fi

# create a new pid file
echo $$ > $PIDFILE

export CI_ROOT=$HOME_DIR/basin

# Remove the cron job by puppet, we only need the papply to be run once
puppet apply --detailed-exitcodes -e "
  # puppet script
  cron { '$PAPPLY_CRON':
    ensure  => absent,
    command => '/bin/bash $HOME_DIR/ci/bin/basin_papply.sh $@',
    user    => 'root',
    minute  => '*/$INTERVAL',
  }"

# update the /etc/hosts
pushd $HOME_DIR/basin
tools/with_venv.sh python basin/bin/basin_sethosts.py --template $HOME_DIR/basin/basin/conf/hosts.tpl
popd

# tarim
echo Puppet apply Tarim setting...
/bin/bash $CI_ROOT/tarim/bin/papply.sh $@

# qaidam
#echo Puppet apply Qaidam setting...
#/bin/bash $CI_ROOT/qaidam/bin/papply.sh $@

# jungar
#echo Puppet apply Jungar setting...
#/bin/bash $CI_ROOT/jungar/bin/papply.sh $@

rm $PIDFILE

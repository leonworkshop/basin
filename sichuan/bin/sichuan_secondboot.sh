#!/bin/bash

#
# Copyright 2014, Leon's Workshop Ltd.
# All rights reserved.
#

HOME_DIR=/opt/shucaibao
STATE_FILE=$HOME_DIR/run/sichuan_state

. $HOME_DIR/ci/sichuan/bin/sichuan_functions


print_msg "============================================"
print_msg ""
print_msg " Shucaibao Sichuan Server Machine Secondboot"
print_msg ""
print_msg "============================================"

if [[ $DEBUG != "true" ]]; then
  state=$(get_system_state)
  if [[ $state == "system_bootstrap" ]]; then
    print_msg "sichuan node bootstrap is not done yet."
    exit 1
  fi

  if [[ $state != "system_secondboot" ]]; then
    print_msg "sichuan node is not ready for secondboot."
    exit 0
  fi
fi

#pushd $HOME_DIR
#run_with_retry "wget http://collectd.org/files/collectd-5.4.1.tar.gz"
#tar xvf collectd-5.4.1.tar.gz
#cd collectd-5.4.1
#./configure --prefix=/usr --sysconfdir=/etc/collectd --localstatedir=/var --libdir=/usr/lib --mandir=/usr/share/man --enable-all-plugins
#make all install
#cd ..
#rm -rf collectd-5.4.1*
#print_msg "install collectd"
#popd


#print_msg "----------> get the latest build bits <----------"
# Get the specified shucaibao build bits
#pushd $HOME_DIR/ci
#if [[ $DEBUG == "true" ]]; then
#  tools/with_venv.sh python sichuan/bin/sichuan_deploy.py --home $HOME_DIR --pmt $HOME_DIR/sites/xmt/pmt.yaml --bmt $HOME_DIR/sites/xmt/bmt.yaml --console --verbose
#else
#  tools/with_venv.sh python sichuan/bin/sichuan_deploy.py --home $HOME_DIR --pmt $HOME_DIR/sites/xmt/pmt.yaml --bmt $HOME_DIR/sites/xmt/bmt.yaml
#fi
#if [ $? -ne 0 ]; then
#  system_bad "Failed in sichuan_deploy script."
#  exit 1
#fi
#popd

print_msg "----------> apply the latest build bits <----------"
# Apply the current puppet config
PUPPETDIR=$HOME_DIR/basin/sichuan/puppet
if [[ $DEBUG == "true" ]]; then
  puppet apply --detailed-exitcodes ${PUPPETDIR}/manifests/sites.pp --modulepath=${PUPPETDIR}/modules:/etc/puppet/modules
else
  puppet apply --detailed-exitcodes ${PUPPETDIR}/manifests/sites.pp --modulepath=${PUPPETDIR}/modules:/etc/puppet/modules --logdest syslog
fi
if [ $? -eq 2 ]; then
  system_ready "Completed secondboot successfully."
else
  system_bad "failed in appling the Shucaibao build bits"
  exit 1
fi

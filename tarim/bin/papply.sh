#!/bin/bash
#
# Copyright 2014, Leon's Workshop Ltd, All rights reserved.
#
# The entry for setting up the tarim.
#

. $HOME_DIR/basin/basin/bin/basin_functions

export FACTER_tarim_root_dir=$(dirname $(readlink -m $BASH_SOURCE))/..
export FACTER_puppet_dir=$FACTER_tarim_root_dir/puppet
export FACTER_graphite_sources_dir=$FACTER_tarim_root_dir/graphite

GRAPHITE_ROOT=/opt/graphite
SOURCE_ROOT=/opt/shucaibao/basin

source $GRAPHITE_ROOT/bin/activate
sudo puppet apply ${FACTER_puppet_dir}/manifests/sites.pp --modulepath=${FACTER_puppet_dir}/modules:/etc/puppet/modules:$SOURCE_ROOT/sichuan/puppet/modules $@

if [[ $? -ne 2 ]]; then
  # move to config_fault if failure happens
  config_fault "Fail in tarim_deploy.py apply tarim config"
  echo "Fail in tarim_deploy.py"
  exit 1
fi

exit 0

#!/bin/bash
#
# Copyright 2014, Leon's Workshop Ltd, All rights reserved.
#
# The entry for setting up the tarim.
#

export FACTER_tarim_root_dir=$(dirname $(readlink -m $BASH_SOURCE))/..
export FACTER_puppet_dir=$FACTER_tarim_root_dir/puppet
export FACTER_graphite_sources_dir=$FACTER_tarim_root_dir/graphite

puppet apply ${FACTER_puppet_dir}/manifests/sites.pp --modulepath=${FACTER_puppet_dir}/modules:/etc/puppet/modules $@

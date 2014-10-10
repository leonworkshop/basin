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

# install credis lib
cd /tmp/
wget http://credis.googlecode.com/files/credis-0.2.3.tar.gz
tar xzf credis*gz
cd credis*
cat > /tmp/patch.credis << EOP
--- ../credis_2/credis-0.2.3/credis.c   2010-08-27 01:57:25.000000000 -0700
+++ ../credis-0.2.3/credis.c    2014-01-28 22:39:42.000000000 -0800
@@ -754,7 +754,7 @@
    * first 1.1.0 release(?), e.g. stable releases 1.02 and 1.2.6 */
   if (cr_sendfandreceive(rhnd, CR_BULK, "INFO\r\n") == 0) {
     int items = sscanf(rhnd->reply.bulk,
-                       "redis_version:%d.%d.%d\r\n",
+                       "# Server\r\nredis_version:%d.%d.%d\r\n",
                        &(rhnd->version.major),
                        &(rhnd->version.minor),
                        &(rhnd->version.patch));
EOP
# see the patch lower down https://code.google.com/p/credis/wiki/Examples
patch -p2 < /tmp/patch.credis
make
cp *.h /usr/include/
cp *.so /usr/lib/
cp *.a /usr/lib/
cp libcredis.so /usr/lib/


system_ready "Completed secondboot successfully."

echo "----------> apply the every service puppets <----------"

# Apply the puppet config
exec /bin/bash `dirname $BASH_SOURCE`/basin_papply.sh

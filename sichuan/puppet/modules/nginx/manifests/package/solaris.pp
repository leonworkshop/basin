# Class: nginx::package::solaris
#
# This module manages NGINX package installation on solaris based systems
#
# Parameters:
#
# *package_name*
# Needs to be specified. SFEnginx,CSWnginx depending on where you get it.
#
<<<<<<< HEAD
# *package_source* 
=======
# *package_source*
>>>>>>> 3427ab91609d753446ab8fcfde4ff25cd9c5c290
# Needed in case of Solaris 10.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# This class file is not called directly
class nginx::package::solaris(
    $package_name   = undef,
    $package_source = '',
    $package_ensure = 'present'
  ){
  package { $package_name:
<<<<<<< HEAD
	ensure 		=> $package_ensure,
  	source 		=> $package_source
=======
    ensure => $package_ensure,
    source => $package_source
>>>>>>> 3427ab91609d753446ab8fcfde4ff25cd9c5c290
  }
}

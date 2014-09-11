# Class: nginx::service
#
# This module manages NGINX service management and vhost rebuild
#
# Parameters:
#
# There are no default parameters for this class.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# This class file is not called directly
class nginx::service(
  $configtest_enable = $nginx::configtest_enable,
  $service_restart   = $nginx::service_restart,
  $service_ensure    = $nginx::service_ensure,
) {
<<<<<<< HEAD
  
=======

>>>>>>> 3427ab91609d753446ab8fcfde4ff25cd9c5c290
  $service_enable = $service_ensure ? {
    running => true,
    absent => false,
    stopped => false,
<<<<<<< HEAD
    default => true,
  }

  service { 'nginx':
    ensure     => $service_ensure,
=======
    'undef' => undef,
    default => true,
  }

  if $service_ensure == 'undef' {
    $service_ensure_real = undef
  } else {
    $service_ensure_real = $service_ensure
  }

  service { 'nginx':
    ensure     => $service_ensure_real,
>>>>>>> 3427ab91609d753446ab8fcfde4ff25cd9c5c290
    enable     => $service_enable,
    hasstatus  => true,
    hasrestart => true,
  }
  if $configtest_enable == true {
    Service['nginx'] {
      restart => $service_restart,
    }
  }
}

# == Class meili::service
#

class meili::service inherits meili {
  if !($service_ensure in ['present', 'absent']) {
    fail("service_ensure parameter must be 'present' or 'absent'")
  }

  if $service_manage == true {
    supervisor::service {
      $service_name:
        ensure            => $service_ensure,
        enable            => $service_enable,
        command           => $start_command,
        directory         => '/',
# FIX it:
# Meili has to be start as "root" privilege. Didn't
# figure out the root cause yet.
#        user              => $user,
#        group             => $group,
        user => 'root',
        group => 'root',
        autorestart       => $service_autorestart,
        startsecs         => $service_startsecs,
        retries           => $service_retries,
        stopsignal        => $service_stopsignal,
        stopasgroup       => $service_stopasgroup,
        stdout_logfile_maxsize => $service_stdout_logfile_maxsize,
        stdout_logfile_keep    => $service_stdout_logfile_keep,
        stderr_logfile_maxsize => $service_stderr_logfile_maxsize,
        stderr_logfile_keep    => $service_stderr_logfile_keep,
        require                => [  Class['meili::config'], Class['::supervisor'] ],
    }

    if $service_enable == true {
      exec { 'restart-meili':
        command => 'supervisorctl restart ${service_name}',
        path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
        user  => 'root',
        refreshonly => true,
        onlyif  => 'which supervisorctl &>/dev/null',
        require  => Class['::supervisor'],
      }
    }
  }
}

# == Class shennv::service
#

class shennv::service inherits shennv {
  if !($service_ensure in ['present', 'absent']) {
    fail("service_ensure parameter must be 'present' or 'absent'")
  }

  if $service_manage == true {
    if $mode == 'all' or $mode == 'worker' {
        $service_worker_name = "${service_name}_worker"
        supervisor::service {
            $service_worker_name:
                ensure            => $service_ensure,
                enable            => $service_enable,
                command           => $start_worker_command,
                directory         => '/',
# FIX it:
# shennv has to be start as "root" privilege. Didn't
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
                require => [  Class['shennv::config'], Class['::supervisor'] ],
        }

        if $service_enable == true {
            exec { 'restart-shennv-worker':
                command => 'supervisorctl restart ${service_worker_name}',
                path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
                user  => 'root',
                refreshonly => true,
                onlyif  => 'which supervisorctl &>/dev/null',
                require  => Class['::supervisor'],
            }
        }
    }


    if $mode == 'all' or $mode == 'beat' {
        $service_beat_name = "${service_name}_beat"
        supervisor::service {
            $service_beat_name:
                ensure            => $service_ensure,
                enable            => $service_enable,
                command           => $start_beat_command,
                directory         => '/',
# FIX it:
# shennv has to be start as "root" privilege. Didn't
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
                require => [  Class['shennv::config'], Class['::supervisor'] ],
        }

        if $service_enable == true {
            exec { 'restart-shennv-beat':
                command => 'supervisorctl restart ${service_beat_name}',
                path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
                user  => 'root',
                refreshonly => true,
                onlyif  => 'which supervisorctl &>/dev/null',
                require  => Class['::supervisor'],
            }
        }
    }
  }
}

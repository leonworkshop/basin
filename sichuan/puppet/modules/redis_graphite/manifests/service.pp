
class redis_graphite::service inherits redis_graphite {
    if !($service_ensure in ['present', 'absent']) {
      fail("service_ensure parameter must be 'present' or 'absent'")
    }

    $start_command      = "/usr/bin/python $root_dir/redis-graphite.py --redis-server $redis_host --redis-ports $redis_port --carbon-server $carbon_host --carbon-port $carbon_port --interval $interval"

    if $service_manage == true {
      supervisor::service {
        $service_name:
          ensure            => $service_ensure,
          enable            => $service_enable,
          command           => $start_command,
          directory         => '/',
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
          require                => [  Class['::supervisor'] ],
      }

      if $service_enable == true {
        exec { 'restart-redis-graphite':
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

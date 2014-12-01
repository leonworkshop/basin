
class redis_graphite::params {
    $root_dir           = '/opt/shoowo/basin/sichuan/redis-graphite'

    $redis_host         = '127.0.0.1'
    $redis_port         = 6379
    $carbon_host        = '127.0.0.1'
    $carbon_port        = 2003
    $interval           = 30

    python::pip {'redis':
        ensure => '2.8.0'
    }

    $service_autorestart  = true
    $service_enable       = true
    $service_ensure       = 'present'
    $service_name         = 'redis_graphite'
    $service_manage       = true
    $service_startsecs    = 10
    $service_retries      = 99
    $service_stderr_logfile_keep    = 10
    $service_stderr_logfile_maxsize = '20MB'
    $service_stdout_logfile_keep    = 5
    $service_stdout_logfile_maxsize = '20MB'
    $service_stopasgroup    = true
    $service_stopsignal     = 'INT'
}

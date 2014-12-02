
class redis_graphite (
    $redis_host         = $redis_graphite::params::redis_host,
    $redis_port         = $redis_graphite::params::redis_port,
    $carbon_host        = $redis_graphite::params::carbon_host,
    $carbon_port        = $redis_graphite::params::carbon_port,
    $interval           = $redis_graphite::params::internal,

    $service_autorestart        = hiera("redis_graphite::service_autorestart", $redis_graphite::params::service_autorestart),
    $service_enable             = hiera("redis_graphite::service_enable", $redis_graphite::params::service_enable),
    $service_ensure             = $redis_graphite::params::service_ensure,
    $service_name               = $redis_graphite::params::service_name,
    $service_manage             = $redis_graphite::params::service_manage,
    $service_startsecs          = $redis_graphite::params::service_startsecs,
    $service_retries            = $redis_graphite::params::service_retries,
    $service_stderr_logfile_keep    = $redis_graphite::params::service_stderr_logfile_keep,
    $service_stderr_logfile_maxsize = $redis_graphite::params::service_stderr_logfile_maxsize,
    $service_stdout_logfile_keep    = $redis_graphite::params::service_stdout_logfile_keep,
    $service_stdout_logfile_maxsize = $redis_graphite::params::service_stdout_logfile_maxsize,
    $service_stopasgroup    = hiera("redis_graphite::service_stopasgroup", $redis_graphite::params::service_stopasgroup),
    $service_stopsignal     = $redis_graphite::params::service_stopsignal,

) inherits redis_graphite::params {
    validate_bool($service_autorestart)
    validate_bool($service_enable)
    validate_string($service_ensure)
    validate_string($service_name)

    include "::redis_graphite::service"

    anchor { "redis_graphite::begin": }
    anchor { "redis_graphite::end": }

    Anchor["redis_graphite::begin"]
        -> Class["::redis_graphite::service"]
        -> Anchor["redis_graphite::end"]
}

# define: nginx::resource::location
#
# This definition creates a new location entry within a virtual host
#
# Parameters:
#   [*ensure*]               - Enables or disables the specified location
#     (present|absent)
#   [*internal*]             - Indicates whether or not this loation can be
#     used for internal requests only. Default: false
#   [*vhost*]                - Defines the default vHost for this location
#     entry to include with
#   [*location*]             - Specifies the URI associated with this location
#     entry
#   [*location_allow*]       - Array: Locations to allow connections from.
#   [*location_deny*]        - Array: Locations to deny connections from.
#   [*www_root*]             - Specifies the location on disk for files to be
#     read from. Cannot be set in conjunction with $proxy
#   [*autoindex*]            - Set it on 'on' to activate autoindex directory
#     listing. Undef by default.
#   [*index_files*]          - Default index files for NGINX to read when
#     traversing a directory
#   [*proxy*]                - Proxy server(s) for a location to connect to.
#     Accepts a single value, can be used in conjunction with
#     nginx::resource::upstream
#   [*proxy_redirect*]       - sets the text, which must be changed in
#     response-header "Location" and "Refresh" in the response of the proxied
#     server.
#   [*proxy_read_timeout*]   - Override the default the proxy read timeout
#     value of 90 seconds
#   [*proxy_connect_timeout*] - Override the default the proxy connect timeout
#     value of 90 seconds
#   [*proxy_set_header*]     - Array of vhost headers to set
#   [*fastcgi*]              - location of fastcgi (host:port)
#   [*fastcgi_param*]        - Set additional custom fastcgi_params
#   [*fastcgi_params*]       - optional alternative fastcgi_params file to use
#   [*fastcgi_script*]       - optional SCRIPT_FILE parameter
#   [*fastcgi_split_path*]   - Allows settings of fastcgi_split_path_info so
#     that you can split the script_name and path_info via regex
#   [*ssl*]                  - Indicates whether to setup SSL bindings for
#     this location.
#   [*ssl_only*]             - Required if the SSL and normal vHost have the
#     same port.
#   [*location_alias*]       - Path to be used as basis for serving requests
#     for this location
#   [*stub_status*]          - If true it will point configure module
#     stub_status to provide nginx stats on location
#   [*raw_prepend*]          - A single string, or an array of strings to
#     prepend to the location directive (after custom_cfg directives). NOTE:
#     YOU are responsible for a semicolon on each line that requires one.
#   [*raw_append*]           - A single string, or an array of strings to
#     append to the location directive (after custom_cfg directives). NOTE:
#     YOU are responsible for a semicolon on each line that requires one.
#   [*location_custom_cfg*]  - Expects a hash with custom directives, cannot
#     be used with other location types (proxy, fastcgi, root, or stub_status)
#   [*location_cfg_prepend*] - Expects a hash with extra directives to put
#     before anything else inside location (used with all other types except
#     custom_cfg)
#   [*location_custom_cfg_prepend*]   - Expects a array with extra directives
#     to put before anything else inside location (used with all other types
#     except custom_cfg). Used for logical structures such as if.
#   [*location_custom_cfg_append*]    - Expects a array with extra directives
#     to put before anything else inside location (used with all other types
#     except custom_cfg). Used for logical structures such as if.
#   [*location_cfg_append*]  - Expects a hash with extra directives to put
#     after everything else inside location (used with all other types except
#     custom_cfg)
#   [*try_files*]            - An array of file locations to try
#   [*option*]               - Reserved for future use
#   [*proxy_cache*]           - This directive sets name of zone for caching.
#     The same zone can be used in multiple places.
#   [*proxy_cache_valid*]     - This directive sets the time for caching
#     different replies.
#   [*proxy_method*]         - If defined, overrides the HTTP method of the
#     request to be passed to the backend.
#   [*proxy_set_body*]       - If defined, sets the body passed to the backend.
#   [*auth_basic*]            - This directive includes testing name and password
#     with HTTP Basic Authentication.
#   [*auth_basic_user_file*]  - This directive sets the htpasswd filename for
#     the authentication realm.
#   [*priority*]              - Location priority. Default: 500. User priority
#     401-499, 501-599. If the priority is higher than the default priority,
#     the location will be defined after root, or before root.
#
#
# Actions:
#
# Requires:
#
# Sample Usage:
#  nginx::resource::location { 'test2.local-bob':
#    ensure   => present,
#    www_root => '/var/www/bob',
#    location => '/bob',
#    vhost    => 'test2.local',
#  }
#
#  Custom config example to limit location on localhost,
#  create a hash with any extra custom config you want.
#  $my_config = {
#    'access_log' => 'off',
#    'allow'      => '127.0.0.1',
#    'deny'       => 'all'
#  }
#  nginx::resource::location { 'test2.local-bob':
#    ensure              => present,
#    www_root            => '/var/www/bob',
#    location            => '/bob',
#    vhost               => 'test2.local',
#    location_cfg_append => $my_config,
#  }
#
#  Add Custom fastcgi_params
#  nginx::resource::location { 'test2.local-bob':
#    ensure   => present,
#    www_root => '/var/www/bob',
#    location => '/bob',
#    vhost    => 'test2.local',
#    fastcgi_param => {
#       'APP_ENV' => 'local',
#    }
#  }

define nginx::resource::location (
  $ensure               = present,
  $internal             = false,
  $location             = $name,
  $vhost                = undef,
  $www_root             = undef,
  $autoindex            = undef,
  $index_files          = [
    'index.html',
    'index.htm',
    'index.php'],
  $proxy                = undef,
  $proxy_redirect       = $nginx::config::proxy_redirect,
  $proxy_read_timeout   = $nginx::config::proxy_read_timeout,
  $proxy_connect_timeout = $nginx::config::proxy_connect_timeout,
  $proxy_set_header     = $nginx::config::proxy_set_header,
  $fastcgi              = undef,
  $fastcgi_param        = undef,
  $fastcgi_params       = "${nginx::config::conf_dir}/fastcgi_params",
  $fastcgi_script       = undef,
  $fastcgi_split_path   = undef,
  $ssl                  = false,
  $ssl_only             = false,
  $location_alias       = undef,
  $location_allow       = undef,
  $location_deny        = undef,
  $option               = undef,
  $stub_status          = undef,
  $raw_prepend          = undef,
  $raw_append           = undef,
  $location_custom_cfg  = undef,
  $location_cfg_prepend = undef,
  $location_cfg_append  = undef,
  $location_custom_cfg_prepend  = undef,
  $location_custom_cfg_append   = undef,
  $try_files            = undef,
  $proxy_cache          = false,
  $proxy_cache_valid    = false,
  $proxy_method         = undef,
  $proxy_set_body       = undef,
  $auth_basic           = undef,
  $auth_basic_user_file = undef,
  $rewrite_rules        = [],
  $priority             = 500
) {

  include nginx::params
  $root_group = $nginx::params::root_group

  File {
    owner  => 'root',
    group  => $root_group,
    mode   => '0644',
    notify => Class['nginx::service'],
  }

  validate_re($ensure, '^(present|absent)$',
    "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'.")
  validate_string($location)
  if ($vhost != undef) {
    validate_string($vhost)
  }
  if ($www_root != undef) {
    validate_string($www_root)
  }
  if ($autoindex != undef) {
    validate_string($autoindex)
  }
  validate_array($index_files)
  if ($proxy != undef) {
    validate_string($proxy)
  }
  validate_string($proxy_redirect)
  validate_string($proxy_read_timeout)
  validate_string($proxy_connect_timeout)
  validate_array($proxy_set_header)
  if ($fastcgi != undef) {
    validate_string($fastcgi)
  }
  if ($fastcgi_param != undef) {
    validate_hash($fastcgi_param)
  }
  validate_string($fastcgi_params)
  if ($fastcgi_script != undef) {
    validate_string($fastcgi_script)
  }
  if ($fastcgi_split_path != undef) {
    validate_string($fastcgi_split_path)
  }

  validate_bool($internal)

  validate_bool($ssl)
  validate_bool($ssl_only)
  if ($location_alias != undef) {
    validate_string($location_alias)
  }
  if ($location_allow != undef) {
    validate_array($location_allow)
  }
  if ($location_deny != undef) {
    validate_array($location_deny)
  }
  if ($option != undef) {
    warning('The $option parameter has no effect and is deprecated.')
  }
  if ($stub_status != undef) {
    validate_bool($stub_status)
  }
  if ($raw_prepend != undef) {
    if (is_array($raw_prepend)) {
      validate_array($raw_prepend)
    } else {
      validate_string($raw_prepend)
    }
  }
  if ($raw_append != undef) {
    if (is_array($raw_append)) {
      validate_array($raw_append)
    } else {
      validate_string($raw_append)
    }
  }
  if ($location_custom_cfg != undef) {
    validate_hash($location_custom_cfg)
  }
  if ($location_cfg_prepend != undef) {
    validate_hash($location_cfg_prepend)
  }
  if ($location_cfg_append != undef) {
    validate_hash($location_cfg_append)
  }
  if ($try_files != undef) {
    validate_array($try_files)
  }
  if ($proxy_cache != false) {
    validate_string($proxy_cache)
  }
  if ($proxy_cache_valid != false) {
    validate_string($proxy_cache_valid)
  }
  if ($proxy_method != undef) {
    validate_string($proxy_method)
  }
  if ($proxy_set_body != undef) {
    validate_string($proxy_set_body)
  }
  if ($auth_basic != undef) {
    validate_string($auth_basic)
  }
  if ($auth_basic_user_file != undef) {
    validate_string($auth_basic_user_file)
  }
  if !is_integer($priority) {
    fail('$priority must be an integer.')
  }
  validate_array($rewrite_rules)
  if ($priority < 401) or ($priority > 899) {
    fail('$priority must be in the range 401-899.')
  }

  # # Shared Variables
  $ensure_real = $ensure ? {
    'absent' => absent,
    default  => file,
  }

  $vhost_sanitized = regsubst($vhost, ' ', '_', 'G')
  $config_file = "${nginx::config::conf_dir}/sites-available/${vhost_sanitized}.conf"

  $location_sanitized_tmp = regsubst($location, '\/', '_', 'G')
  $location_sanitized = regsubst($location_sanitized_tmp, "\\\\", '_', 'G')

  ## Check for various error conditions
  if ($vhost == undef) {
    fail('Cannot create a location reference without attaching to a virtual host')
  }
#  if (($www_root == undef) and ($proxy == undef) and ($location_alias == undef) and ($stub_status == undef) and ($fastcgi == undef) and ($location_custom_cfg == undef)) {
#    fail('Cannot create a location reference without a www_root, proxy, location_alias, fastcgi, stub_status, or location_custom_cfg defined')
#  }
  if (($www_root != undef) and ($proxy != undef)) {
    fail('Cannot define both directory and proxy in a virtual host')
  }

  # fastcgi_script is deprecated
  if ($fastcgi_script != undef) {
    warning('The $fastcgi_script parameter is deprecated; please use $fastcgi_param instead to define custom fastcgi_params!')
  }

  # Use proxy or fastcgi template if $proxy is defined, otherwise use directory template.
  if ($proxy != undef) {
    $content_real = template('nginx/vhost/locations/proxy.erb')
  } elsif ($location_alias != undef) {
    $content_real = template('nginx/vhost/locations/alias.erb')
  } elsif ($stub_status != undef) {
    $content_real = template('nginx/vhost/locations/stub_status.erb')
  } elsif ($fastcgi != undef) {
    $content_real = template('nginx/vhost/locations/fastcgi.erb')
  } elsif ($www_root != undef) {
    $content_real = template('nginx/vhost/locations/directory.erb')
  } else {
    $content_real = template('nginx/vhost/locations/empty.erb')
  }

  if $fastcgi != undef and !defined(File[$fastcgi_params]) {
    file { $fastcgi_params:
      ensure  => present,
      mode    => '0770',
      content => template('nginx/vhost/fastcgi_params.erb'),
    }
  }

  ## Create stubs for vHost File Fragment Pattern
  if ($ssl_only != true) {
    $tmpFile=md5("${vhost_sanitized}-${priority}-${location_sanitized}")

    concat::fragment { "${tmpFile}":
      ensure  => present,
      target  => $config_file,
      content => join([
        template('nginx/vhost/location_header.erb'),
        $content_real,
        template('nginx/vhost/location_footer.erb')
      ], ''),
      order   => "${priority}",
    }
  }

  ## Only create SSL Specific locations if $ssl is true.
  if ($ssl == true or $ssl_only == true) {
    $ssl_priority = $priority + 300

    $sslTmpFile=md5("${vhost_sanitized}-${ssl_priority}-${location_sanitized}-ssl")
    concat::fragment {"${sslTmpFile}":
      ensure  => present,
      target  => $config_file,
      content => join([
        template('nginx/vhost/location_header.erb'),
        $content_real,
        template('nginx/vhost/location_footer.erb')
      ], ''),
      order   => "${ssl_priority}",
    }
  }

  if ($auth_basic_user_file != undef) {
    #Generate htpasswd with provided file-locations
    file { "${nginx::config::conf_dir}/${location_sanitized}_htpasswd":
      ensure => $ensure,
      mode   => '0644',
      source => $auth_basic_user_file,
    }
  }
}

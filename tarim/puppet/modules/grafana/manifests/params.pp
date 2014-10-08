# == Class: grafana
#
# Default parameters
#
class grafana::params {
  $version            = '1.7.0'
  $install_method     = 'archive'
  $install_dir        = '/opt'
  $source_dir         = '/opt/shucaibao/basin/tarim/graphite/grafana'
  $symlink            = false
  $grafana_user       = 'root'
  $grafana_group      = 'root'
  $graphite_host      = 'localhost'
  $graphite_port      = '8000'
  $datasources        = {
    'graphite' => {
      'type'    => 'graphite',
      'url'     => 'http://localhost:8000',
      'default' => 'true' # lint:ignore:quoted_booleans
    },
    'elasticsearch' => {
      'type'      => 'elasticsearch',
      'url'       => 'http://localhost:9200',
      'index'     => 'grafana-dash',
      'grafanaDB' => 'true' # lint:ignore:quoted_booleans
    },
  }
}

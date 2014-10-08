class { '::collectd':
  purge        => true,
  recurse      => true,
  purge_config => true,
  interval => 10
}

class { 'collectd::plugin::logfile':
  log_level => 'info',
  log_file => '/var/log/collected.log'
}

class { 'collectd::plugin::cpu':
}

class { 'collectd::plugin::memory':
}

class { 'collectd::plugin::interface':
  interfaces     => ['lo'],
  ignoreselected => true
}

class { 'collectd::plugin::load':
}

class { 'collectd::plugin::df':
  mountpoints    => ['/alidata1', '/'],
  fstypes        => ['ext3', 'ext4'],
  ignoreselected => false,
}

class { 'collectd::plugin::disk':
  disks          => ['/^xvd/'],
  ignoreselected => false
}

class { 'collectd::plugin::write_graphite':
  graphitehost => '115.29.197.162',
}

class {'collectd::plugin::uptime':
}

class {'collectd::plugin::users':
}

class { 'collectd::plugin::nginx':
  url      => 'https://localhost/status/',
}

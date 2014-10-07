# == Class: graphite::deps
#
# Class to create a Python virtualenv and install all graphite dependencies
# within that sandbox.
#
# With the exception of pycairo which can't be installed by pip. It is
# installed as a system package and symlinked into the virtualenv. This is a
# slightly hacky alternative to `--system-site-packages` which would mess
# with Graphite's other dependencies.
#
class graphite::deps inherits graphite::params {
  $root_dir = $::graphite::params::root_dir

#  python::virtualenv { "$root_dir/.venv": } ->
  python::pip { [
    'gunicorn',
    'Twisted>=11.1.0',
    'tagging>=0.2.1',
    'django==1.5.9',
    'django-tagging>=0.3.1',
    'daemonize>=2.3.1',
    'python-memcached>=1.47',
    'simplejson==2.1.6',
    'python-openid',
    'python-oauth2',
    "django-stronghold==0.2.6",
    "python-social-auth",
  ]:
#    virtualenv => "$root_dir/.venv",
    timeout => 3000,
  }

  ensure_packages(['python-cairo'])

  file { "${root_dir}/lib/python2.7/site-packages/cairo":
    ensure  => link,
    target  => '/usr/lib/python2.7/dist-packages/cairo',
    require => [
#      Python::Virtualenv["$root_dir/.venv"],
      Package['python-cairo'],
    ],
  }
}

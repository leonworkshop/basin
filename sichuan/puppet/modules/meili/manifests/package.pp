# == Class: meili::package
#

class meili::package {
  Exec {
    path      => ['/bin', '/usr/bin', '/usr/local/bin'],
    cwd       => '/',
    tries     => 3,
    try_sleep => 10,
  }

  #### package management
  if $meili::package_ensure == 'present' {
    # Check if we want to install a specific version or not
    if $meili::version == false {

      $package_ensure = $meili::autoupgrade ? {
        true  => 'latest',
        false => 'present',
      }

    } else {

      # install specific version
      $package_ensure = $meili::version

    }

    # action
    if ($meili::package_url != undef) {

      case $meili::package_provider {
        'package': { $before = Package[$meili::package_name]  }
        default:   { fail("software provider \"${meili::software_provider}\".") }
      }

      $package_dir = $meili::package_dir

      # Create directory to place the package file
      exec { 'create_package_dir_meili':
        cwd     => '/',
        path    => ['/usr/bin', '/bin'],
        command => "rm -rf ${meili::package_dir};mkdir -p ${meili::package_dir}",
      }

      file { $package_dir:
        ensure  => 'directory',
        purge   => $meili::purge_package_dir,
        force   => $meili::purge_package_dir,
        backup  => false,
        require => Exec['create_package_dir_meili'],
      }

      $filenameArray = split($meili::package_url, '/')
      $basefilename = $filenameArray[-1]

      $sourceArray = split($meili::package_url, ':')
      $protocol_type = $sourceArray[0]

      $extArray = split($basefilename, '\.')
      $ext = $extArray[-1]

      $pkg_source = "${package_dir}/${basefilename}"

      case $protocol_type {

        puppet: {

          file { $pkg_source:
            ensure  => present,
            source  => $meili::package_url,
            require => File[$package_dir],
            backup  => false,
            before  => $before
          }

        }
        ftp, https, http: {

          exec { 'download_package_meili':
            command => "${meili::params::download_tool} ${pkg_source} ${meili::package_url} 2> /dev/null",
            creates => $pkg_source,
            timeout => $meili::package_dl_timeout,
            require => File[$package_dir],
            before  => $before
          }

        }
        file: {

          $source_path = $sourceArray[1]
          file { $pkg_source:
            ensure  => present,
            source  => $source_path,
            require => File[$package_dir],
            backup  => false,
            before  => $before
          }

        }
        default: {
          fail("Protocol must be puppet, file, http, https, or ftp. You have given \"${protocol_type}\"")
        }
      }

      if ($meili::package_provider == 'package') {

        case $ext {
          'deb':   { $pkg_provider = 'dpkg' }
          'rpm':   { $pkg_provider = 'rpm'  }
          default: { fail("Unknown file extention \"${ext}\".") }
        }

      }

    } else {
      $pkg_source = undef
      $pkg_provider = undef
    }

  # Package removal
  } else {

    $pkg_source = undef
    if ($::operatingsystem == 'OpenSuSE') {
      $pkg_provider = 'rpm'
    } else {
      $pkg_provider = undef
    }
    $package_ensure = 'absent'

    $package_dir = $meili::package_dir

    file { $package_dir:
      ensure => 'absent',
      purge  => true,
      force  => true,
      backup => false
    }

  }

  if ($meili::package_provider == 'package') {

    package { $meili::package_name:
      ensure            => $package_ensure,
      source            => $pkg_source,
      provider          => $pkg_provider,
    }

  } else {
    fail("\"${meili::package_provider}\" is not supported")
  }
}

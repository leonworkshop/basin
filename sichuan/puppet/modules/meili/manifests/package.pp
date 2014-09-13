# == Class: meili::package
#

class meili::package inherits meili {
    $rootdir = "${root_dir}"
    $srcdir = "${source_dir}"

    Exec {
        path      => ['/bin', '/usr/bin', '/usr/local/bin'],
        cwd       => '/',
        tries     => 3,
        try_sleep => 10,
    }

    if $meili::package_ensure == 'present' {
        file {"${rootdir}":
            ensure => 'link',
            target => "${srcdir}"
        }
    } else {
        file {"${rootdir}":
            ensure => absent
        }
    }
}

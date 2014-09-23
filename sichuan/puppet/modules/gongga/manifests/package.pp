# == Class: gongga::package
#

class gongga::package inherits gongga {
    $rootdir = "${root_dir}"
    $srcdir = "${source_dir}"

    Exec {
        path      => ['/bin', '/usr/bin', '/usr/local/bin'],
        cwd       => '/',
        tries     => 3,
        try_sleep => 10,
    }

    if $gongga::package_ensure == 'present' {
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

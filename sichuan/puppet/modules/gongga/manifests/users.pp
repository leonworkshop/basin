# == Class gongga::users
#
class gongga::users inherits gongga {

  if $user_manage == true {
        group { $group:
            ensure => $group_ensure,
        }

        user {$user:
            ensure     => $user_ensure,
            home       => $user_home,
            shell      => $shell,
            comment    => $user_description,
            groups     => ["$group"],
            managehome => $user_managehome,
        }

  }

}

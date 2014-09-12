# == Class meili::users
#
class meili::users inherits meili {

  if $user_manage == true {

    user { $user:
      ensure     => $user_ensure,
      home       => $user_home,
      shell      => $shell,
      comment    => $user_description,
      groups     => ["$group"],
      managehome => $user_managehome,
    }

  }

}

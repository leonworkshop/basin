# puppet-supervisor

[Wirbelsturm](https://github.com/miguno/wirbelsturm)-compatible [Puppet](http://puppetlabs.com/) module to deploy
[supervisord](http://www.supervisord.org/) version 3.0+.

You can use this Puppet module to deploy supervisord to physical and virtual machines, for instance via your existing
internal or cloud-based Puppet infrastructure and via a tool such as [Vagrant](http://www.vagrantup.com/) for local
and remote deployments.

Also, you can use this Puppet module to run services such as [Apache ZooKeeper](http://zookeeper.apache.org/) under
process supervision via supervisord.  See [puppet-zookeeper](https://github.com/miguno/puppet-zookeeper) for an example.

---

Table of Contents

* <a href="#quickstart">Quick start</a>
* <a href="#features">Features</a>
* <a href="#requirements">Requirements and assumptions</a>
* <a href="#installation">Installation</a>
* <a href="#configuration">Configuration</a>
* <a href="#usage">Usage</a>
    * <a href="#configuration-examples">Configuration examples</a>
        * <a href="#hiera">Using Hiera</a>
        * <a href="#manifests">Using Puppet manifests</a>
    * <a href="#service-management">Service management</a>
    * <a href="#log-files">Log files</a>
* <a href="#todo">TODO</a>
* <a href="#changelog">Change log</a>
* <a href="#contributing">Contributing</a>
* <a href="#credits">Credits</a>
* <a href="#license">License</a>

---

<a name="quickstart"></a>

# Quick start

See section [Usage](#usage) below.


<a name="features"></a>

# Features

* Decouples code (Puppet manifests) from configuration data (Hiera) through the use of Puppet parameterized classes,
  i.e. class parameters.  Hence you should use Hiera to control how supervisord is deployed and to which machines.
* Supports RHEL OS family (e.g. RHEL 6, CentOS 6, Amazon Linux) as well as the Debian/Ubuntu family.  However our
  own usage and testing are almost exclusively done on the RHEL family.
    * Code contributions to support additional OS families are welcome!


<a name="requirements"></a>

# Requirements and assumptions

* This module requires that the target machines to which you are deploying supervisord have **yum repositories**
  **configured** for pulling the supervisord 3.0+ package (i.e. RPM).
    * Note: The supervisord version in EPEL6 is the outdated 2.x version, which _is not_ supported by this module.
    * We provide [wirbelsturm-rpm-supervisord](https://github.com/miguno/wirbelsturm-rpm-supervisord) so that you can
      conveniently build such an RPM yourself.
* This module has primarily been tested on the RHEL OS family.


<a name="installation"></a>

# Installation

It is recommended to use [librarian-puppet](https://github.com/rodjek/librarian-puppet) to add this module to your
Puppet setup.

Add the following lines to your `Puppetfile`:

```
# Add the stdlib dependency as hosted on public Puppet Forge.
#
# We intentionally do not include the stdlib dependency in our Modulefile to make it easier for users who decided to
# use internal copies of stdlib so that their deployments are not coupled to the availability of PuppetForge.  While
# there are tools such as puppet-library for hosting internal forges or for proxying to the public forge, not everyone
# is actually using those tools.
mod 'puppetlabs/stdlib'

mod 'supervisor',
  :git => 'https://github.com/miguno/puppet-supervisor.git'
```

Then use librarian-puppet to install (or update) the Puppet module.


<a name="configuration"></a>

# Configuration

* See [init.pp](manifests/init.pp) for the list of currently supported configuration parameters.  These should be self-explanatory.
* See [params.pp](manifests/params.pp) for the default values of those configuration parameters.


<a name="usage"></a>

# Usage

**IMPORTANT: Make sure you read and follow the [Requirements and assumptions](#requirements) section above.**
**Otherwise the examples below will of course not work.**


<a name="configuration-examples"></a>

## Configuration examples


<a name="hiera"></a>

### Using Hiera

Simple example, using default settings.

```yaml
---
classes:
  - supervisor
```

More sophisticated example that overrides some of the default settings:

```yaml
---
classes:
  - supervisor

supervisor::logfile_maxbytes: '20MB'
supervisor::logfile_backups: 5
```


<a name="manifests"></a>

### Using Puppet manifests

_Note: It is recommended to use Hiera to control deployments instead of using this module in your Puppet manifests_
_directly._

TBD


<a name="service-management"></a>

## Service management

To manually start, stop, restart, or check the status of a managed service, respectively:

    $ sudo supervisorctl [start|stop|restart|status] <service-name>

Example:

    $ sudo supervisorctl status zookeeper
    zookeeper                        RUNNING    pid 16461, uptime 2 days, 22:41:21


<a name="log-files"></a>

## Log files

* Supervisord main log file: `/var/log/supervisor/supervisord.log`
* Supervisord log files related to managed processes:
    * `/var/log/supervisor/<service-name>/<service-name>.out*`
    * `/var/log/supervisor/<service-name>/<service-name>.err*`


<a name="todo"></a>

# TODO

* Code clean up to ensure consistent code style and following Puppet best practices.
  For instance, `init.pp` has code that should rather belong into `install.pp`.
* Add more unit tests and specs.
* Add Travis CI setup.
* Add rollback/remove functionality to complete purge Supervisord related packages and configuration files from a
  machine.


<a name="changelog"></a>

## Change log

See [CHANGELOG](CHANGELOG.md).


<a name="contributing"></a>

## Contributing to puppet-supervisor

Code contributions, bug reports, feature requests etc. are all welcome.

If you are new to GitHub please read [Contributing to a project](https://help.github.com/articles/fork-a-repo) for how
to send patches and pull requests to puppet-supervisor.


<a name="credits"></a>

# Credits

This module is based on -- and a fork of a fork of -- the great work done by
[plathrop](https://github.com/plathrop/puppet-module-supervisor) and
[mhahn](https://github.com/mhahn/puppet-supervisor) (which itself is a fork of plathrop).


<a name="license"></a>

# License

Copyright © 2013-2014 Michael G. Noll

The [original license](https://github.com/plathrop/puppet-module-supervisor/blob/master/LICENSE) of plathrop is a
[custom license](https://github.com/plathrop/puppet-module-supervisor/blob/master/LICENSE) and lists a copyright
2010 of Digg, Inc.  An archived version of this original license is available at [ORIGINAL_LICENSE](ORIGINAL_LICENSE).

As far as any changes introduced by this fork are concerned (as applicable and compatible with the original license)
the [LICENSE](LICENSE) is used.

_Note: If you are the initial creator of this module and have concerns about the licensing please do contact me!_

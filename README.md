
# Overview

# Pre-requistes

* Vagrant
* Vagrant-hosts plugin
* Puppet Development Kit 

## Install vagrant-host plugin

`vagrant plugin install vagrant-hosts`

## Start Puppet Master and connect to it

  The Vagrant file starts up a CentOS 7 virtual box image and runs a bootstrap script which installs the Puppet RPMS. The
bootstrap script also copies a few Puppet configurations into place. The configuration changes are to modify the amount
of memory the Puppet servers tries to assume and also sets the alt_dns_name configuration setting for the Puppet server.

* `vagrant up util01`
* `vagrant ssh util01`


# Puppet command-line primer

## Show Puppet configuration
`puppet config print`

## Show all unsigned Puppet client certs.
`puppet cert list`

## Show all Puppet client certs, signed and unsigned.
`puppet cert list --all`

## Run puppet client in 'noop' mode
`puppet agent --test --noop --server util01`

## Run puppet client in 'no-noop' mode
`puppet agent --test --server util01`

## Run puppet client in 'no-noop' mode and get more information
`puppet agent --test --debug --server util01`

# Puppet Resource Type Introduction

## References
* https://puppet.com/docs/puppet/4.6/type.html

## /etc/motd - Define Content for Message of the Day

### Objective
  Create a Puppet manifest that will create and manage static contents of /etc/motd

### Steps
 
1. Determine where to create the module.
`puppet config print modulepath`

2. Create directory structure for a Puppet Module
```
cd /etc/puppetlabs/code/environments/production/modules
mkdir motd ; cd motd
mkdir manifests
```

3. Create a Puppet manifest to manage the file
`vi manifests/init.pp`

```
class motd {

  file { '/etc/motd':
    ensure  => present,
    content => "This is your message of the Day. Hello",
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

}
```

4. Apply the Manifest
```
[root@util01 motd]# cd ..
[root@util01 modules]# puppet apply --modulepath=. -e "include motd"
Notice: Compiled catalog for util01.localdomain in environment production in 0.02 seconds
Notice: /Stage[main]/Motd/File[/etc/motd]/content: content changed '{md5}d41d8cd98f00b204e9800998ecf8427e' to '{md5}7f5109f611d84ad417a53023a58d2f4b'
Notice: /Stage[main]/Motd/File[/etc/motd]/mode: mode changed '0644' to '0755'
Notice: Applied catalog in 0.04 seconds
```

5. Create a site manifest
```vi /etc/puppetlabs/code/environments/production/manifests/site.pp```
```
node default {

  include 'motd'

}
```

**Best Practice : Do not put Puppet resources in site/node definitions manifests or vice-versus**

6. Run Puppet Agent to apply the Manifest
``` puppet agent --test --server util01 rm -f /etc/motd
puppet agent --test --server util01
```

7. Remove need to specify Puppet Master

```vi /etc/puppetlabs/puppet/puppet.conf```
Change `server = puppet` to `server = util01`
```
rm -f /etc/motd
puppet agent --test
```

8. Add host entry for puppet.

Using a server name in the configs is problematic if the hosts is down, load-balanced, etc. Lets add a hosts entry for now.
The SSL cert for the puppet master was created in such a way it should accept either.
```vi /etc/puppetlabs/puppet/puppet.conf```
Change `server = util01` to `server = puppet`
```vi /etc/hosts` and append puppet to `10.20.1.11 util01.localdomain util01```
```puppet agent test```


## Puppet Master SSL Cert Fun

1. Append `util02` and `foohost` to the line in /etc/hosts for util01
2. Run puppet `puppet agent --test --server util02`. Did Puppet run successfully?
3. Run puppet `puppet agent --test --server util06`. Did Puppet run succesfully this time?


## /etc/motd  : Static file instead of content

### Resources

### Steps

1. `vi /etc/puppetlabs/code/environments/production/modules/motd/manifests/init.pp`
```
class motd {

  file { '/etc/motd':

    ensure => present,
    source => 'puppet:///modules/motd/motd.txt',
    mode => '0755',
    owner => 'root',
    group => 'root',
  }

}```

2. `puppet agent --test`

3. `mkdir /etc/puppetlabs/code/environments/production/modules/motd/files`
4. `vi /etc/puppetlabs/code/environments/production/modules/motd/files/motd.txt`
5. `puppet agent --test`

## /etc/motd : Use Template to define content of Message of the Day

### References 

* https://puppet.com/docs/puppet/5.0/lang_template_erb.html
* https://puppet.com/docs/puppet/5.5/lang_template.html
* https://docs.puppet.com/facter/

*Note: Puppet Templates in newer versions support epp (Embedded Puppet) as well as the original erb (Embedded Ruby).*


### Steps

1. `mkdir /etc/puppetlabs/code/environments/production/modules/motd/templates`
2.  Look at Puppet "facts"
`facter`
3. `vi /etc/puppetlabs/code/environments/production/modules/motd/files/motd.erb`  # suffix matters
```
Host : <%= @fqdn %>

This is a test of the MOTD. This is only a test. If this had been a real
MOTD you would not read it anyway and just go about your business.

Have a nice day.
```
4. `vi /etc/puppetlabs/code/environments/production/modules/motd/manifests/init.pp`
```
class motd {

  file { '/etc/motd':

    ensure  => present,
    content => template('motd/motd.erb'),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

}
```

5. `puppet agent --test`

## /etc/motd : Use Hiera to define values for Message of the Day

### References

* https://docs.puppet.com/hiera/
* https://puppet.com/docs/hiera/3.3/puppet.html
* https://docs.puppet.com/hiera/3.1/hierarchy.html
* https://puppet.com/docs/hiera/3.3/configuring.html

*Note : Hiera data can be a single, global hiera file or included with the module*
* https://github.com/puppetlabs/puppetlabs-ntp/blob/master/hiera.yaml

*Note : yaml not yml*

### Steps

1. `puppet config print hiera_config`
2. `hiera version`
3. Create a Hierarchy.
```
vi /etc/puppetlabs/puppet/hiera.yaml
```
```
---

:backends:
  - yaml
  - json

:yaml:
  :datadir: "/etc/puppetlabs/code/environments/%{::environment}/data"
:json:
  :datadir: "/etc/puppetlabs/code/environments/%{::environment}/data"

hierarchy:
 - common
```

5. `vi /etc/puppetlabs/code/environments/production/hieradata/common.yaml`
```
---
motd_footer: "Have a nice Day. -wintermute"
```

6. `vi /etc/puppetlabs/code/environments/production/modules/motd/manifests/init.pp`
```
class motd (

  $footer = hiera('motd_footer')
) {

  file { '/etc/motd':

    ensure  => present,
    content => template('motd/motd.erb'),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

}
```

7. `vi /etc/puppetlabs/code/environments/production/modules/motd/templates/motd.erb`
```
Host : <%= @fqdn %>

This is a test of the MOTD. This is only a test. If this had been a real
MOTD you would not read it anyway and just go about your business.

<%= @footer %>
```

8. `puppet agent --test`

## /etc/motd - Install fortune

1. Install CentOS Fortune
`vi /etc/puppetlabs/code/environments/production/modules/motd/manifests/init.pp`
Add
```
  package { 'fortune':
    ensure => latest,
    name   => 'fortune-mod',
  }
```
2. `puppet agent --test` What Happens
3. Add CentOS Epel repository to yum
`vi /etc/puppetlabs/code/environments/production/modules/motd/manifests/init.pp`
Add after the fortune package decleration
```
  package { 'epel-release':
    ensure => latest,
  }
```
4. `puppet agent --test1. What Happened this time?
5. Set `ensure => absent` for both packages and rerun puppet
6. Running puppet twice is bad. Set dependencies
7. Modify fortune package resource decleration. Change ensure to present.
```
  package { 'fortune':
    ensure  => absent,
    name    => 'fortune-mod',
    require => Package['epel-release'],
  }
```
8. Have puppet update MOTD with random fortune message every time it runs
Remove content from file resource. Now just ensure it is there.
```
  file { '/etc/motd':

    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }
<...>
 exec { "update_motd":
   command => "/usr/bin/fortune > /etc/motd",
   require => File['/etc/motd'],
 }
```
*Extra credit. Remove /etc/motd and rerun puppet. What does it do?*
*Might be tempted to use exec if resource does not exist. Use defines or module with custom resource types/providers*
*Best practice is to avoid this, puppet always makes changes. Modifies return code and can affect monitoring*


# Memcache

## Create Memcache Module and install it

1. `cd /etc/puppetlabs/code/environments/production/modules/`
2. `mkdir memcache; cd memcache ; mkdir files manifests templates`
3. `vi manifests/init.pp`
```
# memcache
#
# Main class, includes all other classes
#
# @param package_manage
#   Whether to manage the memcache package. Default value: true.
class memcache (

  $package_ensure,
  $package_manage,
  $package_name

) {

  contain memcache::install  # contain not include...

}
```

4. `vi manifests/install.pp`
```
# @api private
# This class handles the memcache package. Avoid modifying private classes
#
class memcache::install () {

  if $memcache::package_manage {

    package { $memcache::package_name:
      ensure => "$memcache::package_ensure",
    }
  }

}
```

5. `vi /etc/puppetlabs/code/environments/production/manifests/site.pp`
```
node default {

  include 'motd'
  include 'memcache'

}
```

6. `puppet agent --test`
7. `vi /etc/puppetlabs/code/environments/production/data/common.yaml`
```
---

memcache::package_ensure: present
memcache::package_manage: true
memcache::package_name: [ 'memcached' ]

motd_footer: "Have a nice Day. -wintermute"
```
8. `puppet agent --test` 

### Questions

1. Is memcache running?
2. What is its configuration?

## Memcache - Part Two - Controll Services

1. `vi /etc/puppetlabs/code/environments/production/modules/memcache/manifests/services.pp`
```
# @api private
# This class handles the memcache service. Avoid modifying private classes.
class memcache::service {

  if $memcache::service_manage == true {
    service { 'memcached':
      ensure     => $memcache::service_ensure,
      enable     => $memcache::service_enable,
      name       => $memcache::service_name,
      provider   => $memcache::service_provider,
      hasstatus  => true,
      hasrestart => true,
    }
  }

}
```

2. `vi /etc/puppetlabs/code/environments/production/data/common.yaml`
```
---
memcache::package_ensure: present
memcache::package_manage: true
memcache::package_name: [ 'memcached' ]

memcache::service_manage: true
memcache::service_ensure: running
memcache::service_enable: true
memcache::service_name: memcached
memcache::service_provider: ~

motd_footer: "Have a nice Day. -wintermute"
```

3. `vi /etc/puppetlabs/code/environments/production/modules/memcache/manifests/init.pp`
```
# memcache
#
# Main class, includes all other classes
#
# @param package_manage
#   Whether to manage the memcache package. Default value: true.
class memcache (

  $package_ensure,
  $package_manage,
  $package_name,

  $service_manage,
  $service_ensure,
  $service_enable,
  $service_name,
  $service_provider

) {

  contain memcache::install
  contain memcache::service

  Class['::memcache::install']
  -> Class['::memcache::service']

}

```

4. `puppet agent --test`
5. Run puppet
```
puppet agent --test
service memcached stop
puppet agent --test
```

# Puppet Development Kit
1. Add to init.pp
```
  exec { "get_pdk":
    command => '/bin/curl "https://puppet-pdk.s3.amazonaws.com/pdk/1.4.1.2/repos/el/7/puppet5/x86_64/pdk-1.4.1.2-1.el7.x86_64.rpm" > /tmp/pdk-1.4.1.2-1.el7.x86_64.rpm',
    creates => '/tmp/pdk-1.4.1.2-1.el7.x86_64.rpm'
  }

```
2. Run puppet twice. What is different between the two runs?
3. 
```
  exec { "get_pdk":
    command => '/bin/curl "https://puppet-pdk.s3.amazonaws.com/pdk/1.4.1.2/repos/el/7/puppet5/x86_64/pdk-1.4.1.2-1.el7.x86_64.rpm" > /tmp/pdk-1.4.1.2-1.el7.x86_64.rpm',
    creates => '/tmp/pdk-1.4.1.2-1.el7.x86_64.rpm'
  } ~>
  exec { "install_pdk":
    command => '/bin/rpm -ivh /tmp/pdk-1.4.1.2-1.el7.x86_64.rpm',
    refreshonly => true,
  }
```
4. Run puppet, what happens? Remove /tmp/pdk-1.4.1.2-1.el7.x86_64.rpm and rerun puppet

5. ```
cd /etc/puppetlabs/code/environments/production/modules/
cd motd
pdk convert
pdk validate
```

# References

## Puppet Domain Specific Language
* https://puppet.com/docs/puppet/5.3/type.html

## Puppet Modules
* https://github.com/voxpupuli
* https://forge.puppet.com/
* https://github.com/puppetlabs/puppetlabs-ntp

## Puppet Developer Kit
* https://github.com/puppetlabs/pdk

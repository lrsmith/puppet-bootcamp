
# Overview

# Pre-requistes

* Vagrant
* Vagrant-hosts plugin

## Install vagrant-host plugin

`vagrant plugin install vagrant-hosts`

## Start Puppet Master and connect to it

  The Vagrant file starts up a CentOS 7 virtual box image and runs a bootstrap script which installs the Puppet RPMS. The
bootstrap script also copies a few Puppet configurations into place. The configuration changes are to modify the amount
of memory the Puppet servers tries to assume and also sets the alt_dns_name configuration setting for the Puppet server.

* `vagrant up util01`
* `vagrant ssh util01`

# Exercises

## Puppet command Primer

### Show Puppet configuration
`puppet config print`

### Show all unsigned Puppet client certs.
`puppet cert list`

### Show all Puppet client certs, signed and unsigned.
`puppet cert list --all`

### Run puppet client in 'noop' mode
`puppet agent --test --noop --server util01`

### Run puppet client in 'no-noop' mode
`puppet agent --test --server util01`

### Run puppet client in 'no-noop' mode and get more information
`puppet agent --test --debug --server util01`

## /etc/motd

### Objective
  Create a Puppet module that will create and manage static contents of /etc/motd

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
`vi /etc/puppetlabs/code/environments/production/manifests/site.pp`
```
node default {

  include 'motd'

}
```

**Best Practive : Do not put Puppet resources in site/node definitions manifests or vice-versus**

6. Run Puppet Agent to apply the Manifest
```
puppet agent --test --server util01
rm -f /etc/motd
puppet agent --test --server util01
```

7. Remove need to specify Puppet Master

`vi /etc/puppetlabs/puppet/puppet.conf`
Change `server = puppet` to `server = util01`
```
rm -f /etc/motd
puppet agent --test
```

8. Add host entry for puppet.

Using a server name in the configs is problematic if the hosts is down, load-balanced, etc. Lets add a hosts entry for now.
The SSL cert for the puppet master was created in such a way it should accept either.
`vi /etc/puppetlabs/puppet/puppet.conf`
Change `server = util01` to `server = puppet`
`vi /etc/hosts` and append puppet to `10.20.1.11 util01.localdomain util01`
`puppet agent test`


## Puppet Master SSL Cert Fun

1. Append `util02` and `foohost` to the line in /etc/hosts for util01
2. Run puppet `puppet agent --test --server util02`. Did Puppet run successfully?
3. Run puppet `puppet agent --test --server util06`. Did Puppet run succesfully this time?






# References

## Puppet Domain Specific Language
* https://puppet.com/docs/puppet/5.3/type.html

## Puppet Modules
* https://github.com/voxpupuli
* https://forge.puppet.com/
* https://github.com/puppetlabs/puppetlabs-ntp

## Puppet Developer Kit
* https://github.com/puppetlabs/pdk

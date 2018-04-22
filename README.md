
# Overview

# Pre-requistes

* Vagrant
* Vagrant-hosts plugin

## Install vagrant-host plugin

`vagrant plugin install vagrant-hosts`

## Start Puppet Master and connect to it

`vagrant up util01`
`vagrant ssh util01`

The Vagrant file starts up a CentOS 7 virtual box image and runs a bootstrap script which installs the Puppet RPMS. The
bootstrap script also copies a few Puppet configurations into place. The configuration changes are to modify the amount
of memory the Puppet servers tries to assume and also sets the alt_dns_name configuration setting for the Puppet server.

# Labs

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





# References

## Puppet Domain Specific Language
* https://puppet.com/docs/puppet/5.3/type.html

## Puppet Modules
* https://github.com/voxpupuli
* https://forge.puppet.com/
* https://github.com/puppetlabs/puppetlabs-ntp

## Puppet Developer Kit
* https://github.com/puppetlabs/pdk

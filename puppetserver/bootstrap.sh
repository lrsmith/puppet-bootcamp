#!/usr/bin/env bash

rpm -Uvh https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm
yum install -y puppetserver

cp /vagrant/puppetserver/sysconfig /etc/sysconfig/puppetserver
cp /vagrant/puppetserver/puppet.conf /etc/puppetlabs/puppet/puppet.conf

service puppetserver start


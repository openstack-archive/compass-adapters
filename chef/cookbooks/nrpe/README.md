nrpe cookbook
=============
[![Build Status](https://travis-ci.org/tas50/chef-nrpe.svg?branch=master)](https://travis-ci.org/tas50/chef-nrpe)

Chef cookbook to install Nagios NRPE client (was previously part of the Nagios cookbook)

Requirements
------------
### Chef
Chef version 0.10.10+ and Ohai 0.6.12+ are required.

### Platform
* Debian 6.X, 7.X
* FreeBSD 9.X
* Ubuntu 10.04, 12.04, 13.04
* Red Hat Enterprise Linux (CentOS/Amazon/Scientific/Oracle) 5.X, 6.X

**Notes**: This cookbook has been tested on the listed platforms. It may work on other platforms with or without modification.

### Cookbooks
* build-essential
* yum-epel (note: this requires yum cookbook v3.0, which breaks compatibility with many other cookbooks)

Recipes
-------
### default
Installs the NRPE client via packages or source depending on platform and attributes set

Attributes
----------

### platform specific attributes (auto set based on platform)
* `node['nrpe']['install_method']` - whether to install from package or source. Default chosen by platform based on known packages available for NRPE: debian/ubuntu 'package', Redhat/CentOS/Fedora/Scientific: source
* `node['nrpe']['home']` - home directory of NRPE
* `node['nrpe']['conf_dir']` - location of the nrpe configuration
* `node['nrpe']['ssl_lib_dir']` - ssl directory used by NRPE
* `node['nrpe']['pidfile']` - location to store the NRPE pid file
* `node['nrpe']['conf_dir']` - location of the nrpe configuration, default /etc/nagios
* `node['nrpe']['packages']` - nrpe / plugin packages to install. The default attribute for RHEL/Fedora platforms contains a bare minimum set of packages. The full list of available packages is available at: `http://dl.fedoraproject.org/pub/epel/6/x86_64/repoview/letter_n.group.html`
* `node['nrpe']['log_facility']` - log facility for nrpe configuration, default nil (not set)
* `node['nrpe']['plugin_dir']` - location where Monitoring plugins (aka Nagios plugins) go, default '/usr/lib/nagios/plugins'.

### nrpe.conf attributes
* `node['nrpe']['server_port']` - the port nrpe will listen on, default 5666
* `node['nrpe']['server_address']` - the IP the nrpe server will listen on. This allows you to bind to particular IPs in situations where the system has more than one IP. This is particularly handy in determining if nrpe should bind to the internal or public IP in a cloud environment. Set the attribute to the node attribute for the cloud interface you wish to use. Defaults to nil (not enabled)
* `node['nrpe']['log_facility']` - syslog facility to log to, default nil (not set)
* `node['nrpe']['command_prefix']` - command to prefix to every nrpe command (like perhaps sudo), default nil (not set)
* `node['nrpe']['debug']` - debug level nrpe configuration, default 0
* `node['nrpe']['connection_timeout']` - connection timeout for nrpe configuration, default nil (not set)
* `node['nrpe']['dont_blame_nrpe']` - allows the server to send additional values to NRPE via arguments.  this needs to be enabled for most checks to function
* `node['nrpe']['command_timeout']` - the amount of time NRPE will wait for a command to execute before timing out

### urls for source installations
* `node['nrpe']['url']` - url to retrieve NRPE source
* `node['nrpe']['version']` - version of NRPE source to download
* `node['nrpe']['checksum']` - checksum of the NRPE source tarball
* `node['nrpe']['plugins']['url']` - url to retrieve the plugins source from
* `node['nrpe']['plugins']['version']` - version of the plugins source to download
* `node['nrpe']['plugins']['checksum']` - checksum of the plugins source tarball

### authorization and server discovery
* `node['nrpe']['server_role']` - the role that the Nagios server will have in its run list that the clients can search for.
* `node['nrpe']['allowed_hosts']` - additional hosts that are allowed to connect to this client. Must be an array of strings (i.e. `%w(test.host other.host)`). These hosts are added in addition to 127.0.0.1 and IPs that are found via search.
* `node['nrpe']['using_solo_search']` - discover server information in node data_bags even with chef solo through the use of solo-search (https://github.com/edelight/chef-solo-search)
* `node['nrpe']['multi_environment_monitoring']` - search for nagios servers in all environments not just that of the node when building the array of allowed hosts, default 'false'

### user and group attributes
* `node['nrpe']['user']` - NRPE user, default 'nagios'.
* `node['nrpe']['group']` - NRPE group, default 'nagios'.

Resources/Providers
-------------------
### check
The check LWRP provides an easy way to add and remove NRPE checks from within cookbooks.

#### Actions
- `:add` creates a NRPE configuration file and reloads the NRPE process. Default action.
- `:remove` removes the configuration file and reloads the NRPE process

#### Attribute Parameters
- `command_name`  The name of the check. This is the command that you will call from your nagios\_service data bag check
- `warning_condition` String that you will pass to the command with the -w flag
- `critical_condition` String that you will pass to the command with the -c flag
- `command` The actual command to execute (including the path). If this is not specified, this will use `#{node['nrpe']['plugin_dir']}/command_name` as the path to the command.
- `parameters` Any additional parameters you wish to pass to the plugin.

#### Examples
```ruby
# Use LWRP to define check_load
nrpe_check "check_load" do
  command "#{node['nrpe']['plugin_dir']}/check_load"
  warning_condition '10'
  critical_condition '15'
  action :add
end
```

```ruby
# Remove the check_load definition
nrpe_check "check_load" do
  action :remove
end
```


License & Authors
-----------------
- Author:: Joshua Sierles <joshua@37signals.com>
- Author:: Nathan Haneysmith <nathan@getchef.com>
- Author:: Joshua Timberman <joshua@getchef.com>
- Author:: Seth Chisamore <schisamo@getchef.com>
- Author:: Tim Smith <tsmith84@gmail.com>

```text
Copyright 2009, 37signals
Copyright 2009-2013, Chef Software, Inc.
Copyright 2012, Webtrends Inc.
Copyright 2013-2014, Limelight Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

#
# Author:: Joshua Sierles <joshua@37signals.com>
# Author:: Joshua Timberman <joshua@getchef.com>
# Author:: Nathan Haneysmith <nathan@getchef.com>
# Author:: Seth Chisamore <schisamo@getchef.com>
# Author:: Tim Smith <tsmith84@gmail.com>
# Cookbook Name:: nrpe
# Attributes:: default
#
# Copyright 2009, 37signals
# Copyright 2009-2013, Chef Software, Inc.
# Copyright 2012, Webtrends, Inc
# Copyright 2013-2014, Limelight Networks, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# platform specific values
case node['platform_family']
when 'debian'
  default['nrpe']['install_method']    = 'package'
  default['nrpe']['pid_file']          = '/var/run/nagios/nrpe.pid'
  default['nrpe']['home']              = '/usr/lib/nagios'
  default['nrpe']['packages']          = %w(nagios-nrpe-server nagios-plugins nagios-plugins-basic nagios-plugins-standard)
  default['nrpe']['plugin_dir']        = '/usr/lib/nagios/plugins'
  default['nrpe']['conf_dir']          = '/etc/nagios'
  if node['kernel']['machine'] == 'i686'
    default['nrpe']['ssl_lib_dir']     = '/usr/lib/i386-linux-gnu'
  else
    default['nrpe']['ssl_lib_dir']     = '/usr/lib/x86_64-linux-gnu'
  end
  if node['nrpe']['install_method'] == 'package'
    default['nrpe']['service_name']    = 'nagios-nrpe-server'
  else
    default['nrpe']['service_name']    = 'nrpe'
  end
when 'rhel', 'fedora'
  default['nrpe']['install_method']    = 'package'
  default['nrpe']['pid_file']          = '/var/run/nrpe.pid'
  default['nrpe']['packages']          = %w(nrpe nagios-plugins-disk nagios-plugins-load nagios-plugins-procs nagios-plugins-users)
  if node['kernel']['machine'] == 'i686'
    default['nrpe']['home']            = '/usr/lib/nagios'
    default['nrpe']['ssl_lib_dir']     = '/usr/lib'
    default['nrpe']['plugin_dir']      = '/usr/lib/nagios/plugins'
  else
    default['nrpe']['home']            = '/usr/lib64/nagios'
    default['nrpe']['ssl_lib_dir']     = '/usr/lib64'
    default['nrpe']['plugin_dir']      = '/usr/lib64/nagios/plugins'
  end
  default['nrpe']['service_name']      = 'nrpe'
  default['nrpe']['conf_dir']          = '/etc/nagios'
when 'freebsd'
  default['nrpe']['install_method']    = 'package'
  default['nrpe']['pid_file']          = '/var/run/nrpe2/nrpe2.pid'
  default['nrpe']['packages']          = %w(nrpe)
  default['nrpe']['log_facility']      = 'daemon'
  default['nrpe']['service_name']      = 'nrpe2'
  default['nrpe']['conf_dir']          = '/usr/local/etc'
else
  default['nrpe']['install_method']    = 'source'
  default['nrpe']['pid_file']          = '/var/run/nrpe.pid'
  default['nrpe']['home']              = '/usr/lib/nagios'
  default['nrpe']['ssl_lib_dir']       = '/usr/lib'
  default['nrpe']['service_name']      = 'nrpe'
  default['nrpe']['plugin_dir']        = '/usr/lib/nagios/plugins'
  default['nrpe']['conf_dir']          = '/etc/nagios'
end

# nrpe daemon user/group
default['nrpe']['user']  = 'nagios'
default['nrpe']['group'] = 'nagios'

# config file options
default['nrpe']['server_port']        = 5666
default['nrpe']['server_address']     = nil
default['nrpe']['command_prefix']     = nil
default['nrpe']['log_facility']       = nil
default['nrpe']['debug']              = 0
default['nrpe']['dont_blame_nrpe']    = 0
default['nrpe']['command_timeout']    = 60
default['nrpe']['connection_timeout'] = nil

# for plugin from source installation
default['nrpe']['plugins']['url']      = 'https://www.monitoring-plugins.org/download'
default['nrpe']['plugins']['version']  = '1.5'
default['nrpe']['plugins']['checksum'] = 'fcc55e23bbf1c70bcf1a90749d30249955d4668a9b776b2521da023c5c2f2170'

# for nrpe from source installation
default['nrpe']['url']      = 'http://prdownloads.sourceforge.net/sourceforge/nagios'
default['nrpe']['version']  = '2.15'
default['nrpe']['checksum'] = '66383b7d367de25ba031d37762d83e2b55de010c573009c6f58270b137131072'

# authorization options
default['nrpe']['server_role'] = 'monitoring'
default['nrpe']['allowed_hosts'] = nil
default['nrpe']['using_solo_search'] = false
default['nrpe']['multi_environment_monitoring'] = false

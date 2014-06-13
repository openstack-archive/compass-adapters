#
# Author:: Seth Chisamore <schisamo@opscode.com>
# Author:: Tim Smith <tsmith@limelight.com>
# Cookbook Name:: nagios
# Recipe:: server_source
#
# Copyright 2011-2013, Opscode, Inc
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

# Package pre-reqs

include_recipe 'build-essential'
include_recipe 'php'
include_recipe 'php::module_gd'

web_srv = node['nagios']['server']['web_server']

case web_srv
when 'apache'
  include_recipe 'nagios::apache'
else
  include_recipe 'nagios::nginx'
end

pkgs = value_for_platform_family(
  %w( rhel fedora ) => %w( openssl-devel gd-devel tar ),
  'debian' => %w( libssl-dev libgd2-xpm-dev bsd-mailx tar ),
  'default' => %w( libssl-dev libgd2-xpm-dev bsd-mailx tar )
)

pkgs.each do |pkg|
  package pkg do
    action :install
  end
end

group node['nagios']['group'] do
  members [
    node['nagios']['user'],
    web_srv == 'nginx' ? node['nginx']['user'] : node['apache']['user']
  ]
  action :modify
end

version = node['nagios']['server']['version']

remote_file "#{Chef::Config[:file_cache_path]}/#{node['nagios']['server']['name']}-#{version}.tar.gz" do
  source "#{node['nagios']['server']['url']}/#{node['nagios']['server']['name']}-#{version}.tar.gz"
  checksum node['nagios']['server']['checksum']
  action :create_if_missing
end

bash 'compile-nagios' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    tar zxvf #{node['nagios']['server']['name']}-#{version}.tar.gz
    cd #{node['nagios']['server']['src_dir']}
    ./configure --prefix=/usr \
        --mandir=/usr/share/man \
        --bindir=/usr/sbin \
        --sbindir=/usr/lib/cgi-bin/#{node['nagios']['server']['vname']} \
        --datadir=#{node['nagios']['docroot']} \
        --sysconfdir=#{node['nagios']['conf_dir']} \
        --infodir=/usr/share/info \
        --libexecdir=#{node['nagios']['plugin_dir']} \
        --localstatedir=#{node['nagios']['state_dir']} \
        --enable-event-broker \
        --with-nagios-user=#{node['nagios']['user']} \
        --with-nagios-group=#{node['nagios']['group']} \
        --with-command-user=#{node['nagios']['user']} \
        --with-command-group=#{node['nagios']['group']} \
        --with-init-dir=/etc/init.d \
        --with-lockfile=#{node['nagios']['run_dir']}/#{node['nagios']['server']['vname']}.pid \
        --with-mail=/usr/bin/mail \
        --with-perlcache \
        --with-htmurl=/#{node['nagios']['server']['vname']} \
        --with-cgiurl=/cgi-bin/#{node['nagios']['server']['vname']}
    make all
    make install
    make install-init
    make install-config
    make install-commandmode
  EOH
  creates "/usr/sbin/#{node['nagios']['server']['name']}"
end

directory node['nagios']['config_dir'] do
  owner 'root'
  group 'root'
  mode 00755
end

%w( cache_dir log_dir run_dir ).each do |dir|

  directory node['nagios'][dir] do
    owner node['nagios']['user']
    group node['nagios']['group']
    mode '0755'
  end

end

directory "/usr/lib/#{node['nagios']['server']['vname']}" do
  owner node['nagios']['user']
  group node['nagios']['group']
  mode '0755'
end

link "#{node['nagios']['conf_dir']}/stylesheets" do
  to "#{node['nagios']['docroot']}/stylesheets"
end

# if nrpe client is not being installed by source then we need the NRPE plugin
if node['nagios']['client']['install_method'] == 'package'

  include_recipe 'nagios::nrpe_source'

end

if web_srv == 'apache'
  apache_module 'cgi' do
    enable :true
  end
end

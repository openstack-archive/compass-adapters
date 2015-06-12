# Encoding: utf-8
#
# Cookbook Name:: openstack-network
# Recipe:: eswitch
#
# Copyright 2013, AT&T
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

['quantum', 'neutron'].include?(node['openstack']['compute']['network']['service_type']) || return

require 'uri'

# Make Openstack object available in Chef::Recipe
class ::Chef::Recipe
  include ::Openstack
end

include_recipe 'openstack-network::common'

platform_options = node['openstack']['network']['platform']
core_plugin = node['openstack']['network']['core_plugin']
main_plugin = node['openstack']['network']['core_plugin_map'][core_plugin.split('.').last.downcase]

if node['platform_family'] == 'suse'
  if node['lsb']['codename'] == 'UVP'
    template '/etc/init.d/eswitchd' do
      source 'eswitchd.service.erb'
      owner "root"
      group "root"
      mode 00755
    end
  end
end

directory '/var/lib/eswitchd' do
  owner node['openstack']['network']['platform']['user']
  group node['openstack']['network']['platform']['group']
  mode 0755
end

directory '/etc/eswitchd' do
  owner node['openstack']['network']['platform']['user']
  group node['openstack']['network']['platform']['group']
  mode 0755
end

directory '/etc/eswitchd/info' do
  owner node['openstack']['network']['platform']['user']
  group node['openstack']['network']['platform']['group']
  mode 0755
end

template '/etc/eswitchd/eswitchd.conf' do
  source 'eswitchd.conf.erb'
  owner node['openstack']['network']['platform']['user']
  group node['openstack']['network']['platform']['group']
  mode   00644
  notifies :restart, 'service[eswitchd]', :delayed 
end

service 'eswitchd' do
  supports status: true, restart: true
  action [:enable, :start]
end

ruby_block "service eswitchd restart if necessary" do
  block do
    Chef::Log.info("service eswitchd restart")
  end
  not_if "service eswitchd status"
  notifies :restart, 'service[eswitchd]', :immediately
end

include_recipe "openstack-network::sriov_agent"
include_recipe "openstack-network::evs_agent"
include_recipe "openstack-network::servicechain_agent"

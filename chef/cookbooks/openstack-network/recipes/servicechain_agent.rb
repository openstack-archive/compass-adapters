# Encoding: utf-8
#
# Cookbook Name:: openstack-network
# Recipe:: servicechain-agent
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

platform_options['neutron_servicechain_agent_packages'].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options['package_overrides']
  end
end

if node['platform_family'] == 'suse'
  if node['lsb']['codename'] == 'UVP'
    template '/etc/init.d/openstack-neutron-servicechain-agent' do
      source 'openstack-neutron-servicechain-agent.service.erb'
      owner "root"
      group "root"
      mode 00755
    end
  end
end

template '/etc/neutron/servicechain_agent.ini' do
  source 'servicechain_agent.ini.erb'
  owner node['openstack']['network']['platform']['user']
  group node['openstack']['network']['platform']['group']
  mode   00644
  variables(
  )
  notifies :restart, 'service[neutron-servicechain-agent]', :delayed
  action :create
end

service 'neutron-servicechain-agent' do
  service_name platform_options['neutron_servicechain_agent_service']
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/neutron/neutron.conf]', :delayed
end

ruby_block "service neutron-servicechain-agent restart if necessary" do
  not_if "service #{platform_options['neutron_servicechain_agent_service']} status"
  notifies :restart, 'service[neutron-servicechain-agent]', :immediately
end

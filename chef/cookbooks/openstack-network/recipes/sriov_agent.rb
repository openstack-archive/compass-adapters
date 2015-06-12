# Encoding: utf-8
#
# Cookbook Name:: openstack-network
# Recipe:: sriov-agent
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

platform_options['neutron_sriov_agent_packages'].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options['package_overrides']
  end
end

if node['platform_family'] == 'suse'
  if node['lsb']['codename'] == 'UVP'
    template '/etc/init.d/openstack-neutron-sriov-agent' do
      source 'openstack-neutron-sriov-agent.service.erb'
      owner "root"
      group "root"
      mode 00755
    end
  end
end

service 'neutron-sriov-agent' do
  service_name platform_options['neutron_sriov_agent_service']
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/neutron/neutron.conf]', :delayed
end

ruby_block "service neutron-sriov-agent restart if necessary" do
  block do
    Chef::Log.info("service neutron-sriov-agent restart")
  end
  not_if "service #{platform_options['neutron_sriov_agent_service']} status"
  notifies :restart, 'service[neutron-sriov-agent]', :immediately
end

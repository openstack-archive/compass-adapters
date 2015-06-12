# Encoding: utf-8
#
# Cookbook Name:: openstack-network
# Recipe:: opensvswitch
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

if platform_family?('debian')

  # obtain kernel version for kernel header
  # installation on ubuntu and debian
  kernel_ver = node['kernel']['release']
  package "linux-headers-#{kernel_ver}" do
    options platform_options['package_overrides']
    action :upgrade
  end

end

if node['openstack']['network']['openvswitch']['use_source_version']
  if node['lsb'] && node['lsb']['codename'] == 'precise'
    include_recipe 'openstack-network::build_openvswitch_source'
  end
else
  platform_options['neutron_openvswitch_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end
end

if platform_family?('debian')

  # NOTE:(mancdaz):sometimes the openvswitch module does not get reloaded
  # properly when openvswitch-datapath-dkms recompiles it.  This ensures
  # that it does

  begin
    if resources('package[openvswitch-datapath-dkms]')
      execute '/usr/share/openvswitch/scripts/ovs-ctl force-reload-kmod' do
        action :nothing
        subscribes :run, resources('package[openvswitch-datapath-dkms]'), :immediately
      end
    end
  rescue Chef::Exceptions::ResourceNotFound # rubocop:disable HandleExceptions
  end

end

if node['platform_family'] == 'suse'
  if node['lsb']['codename'] == 'UVP'
    template '/etc/init.d/openvswitch-switch' do
      source 'openvswitch-switch.service.erb'
      owner "root"
      group "root"
      mode 00755
    end
  end
end

service 'neutron-openvswitch-switch' do
  service_name platform_options['neutron_openvswitch_service']
  supports status: true, restart: true
  action [:enable, :start]
end

ruby_block "service openvswitch-switch restart if necessary" do
  block do
    Chef::Log.info("service openvswitch-switch restart")
  end
  not_if "service #{platform_options['neutron_openvswitch_service']} status"
  notifies :restart, 'service[neutron-openvswitch-switch]', :immediately
end

# if node.run_list.expand(node.chef_environment).recipes.include?('openstack-network::server')
#   service 'neutron-server' do
#     service_name platform_options['neutron_server_service']
#     supports status: true, restart: true
#     action :nothing
#   end
# end

# execute "chkconfig openvswitch on" do
#   only_if {platform?(%w(fedora redhat centos))}
# end

include_recipe 'openstack-network::openvswitch_agent'

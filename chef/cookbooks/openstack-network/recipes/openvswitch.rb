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

service 'neutron-openvswitch-switch' do
  service_name platform_options['neutron_openvswitch_service']
  supports status: true, restart: true
  action [:enable, :start]
end

if node.run_list.expand(node.chef_environment).recipes.include?('openstack-network::server')
  service 'neutron-server' do
    service_name platform_options['neutron_server_service']
    supports status: true, restart: true
    action :nothing
  end
end

platform_options['neutron_openvswitch_agent_packages'].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options['package_overrides']
  end
end

directory '/etc/neutron/plugins/openvswitch' do
  recursive true
  owner node['openstack']['network']['platform']['user']
  group node['openstack']['network']['platform']['group']
  mode 00700
  only_if { platform_family?('rhel') }
end

openvswitch = address node['openstack']['network']['openvswitch']
template '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini' do
  source 'plugins/openvswitch/ovs_neutron_plugin.ini.erb'
  owner node['openstack']['network']['platform']['user']
  group node['openstack']['network']['platform']['group']
  mode 00644
  variables(
    local_ip: openvswitch
  )
  only_if { platform_family?('rhel', 'suse', 'debian') }
end

template '/etc/init/neutron-plugin-openvswitch-agent.conf' do
  source 'neutron-plugin-openvswitch-agent.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
  only_if { platform_family?('debian') }
end

service 'neutron-plugin-openvswitch-agent' do
  service_name platform_options['neutron_openvswitch_agent_service']
  supports status: true, restart: true
  action :enable
  subscribes :restart, 'template[/etc/neutron/neutron.conf]'
  if platform_family?('rhel', 'suse', 'debian')
    subscribes :restart, 'template[/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini]'
  end
  if platform_family?('debian')
    subscribes :restart, 'template[/etc/init/neutron-plugin-openvswitch-agent.conf]'
  end
end

execute "chkconfig openvswitch on" do
  only_if {platform?(%w(fedora redhat centos))}
end

unless ['nicira', 'plumgrid', 'bigswitch'].include?(main_plugin)
  # create internal network bridge
  int_bridge = node['openstack']['network']['openvswitch']['integration_bridge']
  execute 'create internal network bridge' do
    ignore_failure true
    command "ovs-vsctl add-br #{int_bridge}"
    action :run
    not_if "ovs-vsctl br-exists #{int_bridge}"
    notifies :restart, 'service[neutron-plugin-openvswitch-agent]', :delayed
  end
  
  # create tenant network bridge
  case node['openstack']['network']['openvswitch']['tenant_network_type']
    when 'gre'
      bridge = node['openstack']['network']['openvswitch']['tunnel_bridge']
      cmd = "ovs-vsctl --may-exist add-br #{bridge}"

    when 'vlan'
      bridge_mappings = node['openstack']['network']['openvswitch']['bridge_mappings']
      bridge = bridge_mappings.split(":").map(&:strip).reject(&:empty?)[1]
      interface = bridge.split("-").map(&:strip).reject(&:empty?)[1]
      cmd = "ovs-vsctl --may-exist add-br #{bridge};\
             ovs-vsctl --may-exist add-port #{bridge} #{interface}"

    else
      # "TODO"
      print "The tenant_network_type is not suppported/n"
  end
  if defined?(cmd)
    execute "create tenant network bridge" do
      ignore_failure true
      command cmd
      action :run
      not_if "ovs-vsctl br-exists #{bridge}"
      notifies :restart, "service[neutron-plugin-openvswitch-agent]", :delayed
    end
  end
end

=begin
unless ['nicira', 'plumgrid', 'bigswitch'].include?(main_plugin)
  if ['False', 'false'].include?(node['openstack']['network']['openvswitch']['enable_tunneling']) and \
     not node['openstack']['network']['openvswitch']['bridge_mappings'].to_s.empty?
    bridge_mappings = node['openstack']['network']['openvswitch']['bridge_mappings'].split(',')
    for bridge_mapping in bridge_mappings
      bridge = bridge_mapping.split(':').last
      bridge_iface = bridge.split('-').last
      execute 'create data network bridge' do
        command "ovs-vsctl add-br #{bridge} -- add-port #{bridge} #{bridge_iface}"
        action :run
        not_if "ovs-vsctl br-exists #{bridge}"
        only_if "ip link show #{bridge_iface}"
        notifies :restart, 'service[neutron-plugin-openvswitch-agent]', :delayed
      end
    end
  end
end
=end

if node['openstack']['network']['disable_offload']
  package 'ethtool' do
    action :upgrade
    options platform_options['package_overrides']
  end

  service 'disable-eth-offload' do
    supports restart: false, start: true, stop: false, reload: false
    priority(
      2 => [:start, 19]
    )
    action :nothing
  end

  # a priority of 19 ensures we start before openvswitch
  # at least on ubuntu and debian
  cookbook_file 'disable-eth-offload-script' do
    path '/etc/init.d/disable-eth-offload'
    source 'disable-eth-offload.sh'
    owner 'root'
    group 'root'
    mode '0755'
    notifies :enable, 'service[disable-eth-offload]'
    notifies :start, 'service[disable-eth-offload]'
  end
end

# From http://git.openvswitch.org/cgi-bin/gitweb.cgi?p=openvswitch;a=blob_plain;f=utilities/ovs-dpctl-top.in;h=f43fdeb7ab52e3ef642a22579036249ec3a4bc22;hb=14b4c575c28421d1181b509dbeae6e4849c7da69
cookbook_file 'ovs-dpctl-top' do
  path '/usr/bin/ovs-dpctl-top'
  source 'ovs-dpctl-top'
  owner 'root'
  group 'root'
  mode 0755
end

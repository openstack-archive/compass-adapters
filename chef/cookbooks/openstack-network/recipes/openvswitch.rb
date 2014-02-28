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

require 'uri'

class ::Chef::Recipe
  include ::Openstack
end

include_recipe "openstack-network::common"

platform_options = node["openstack"]["network"]["platform"]
driver_name = node["openstack"]["network"]["interface_driver"].split('.').last.downcase
main_plugin = node["openstack"]["network"]["interface_driver_map"][driver_name]
core_plugin = node["openstack"]["network"]["core_plugin"]

if platform?("ubuntu", "debian")
  # obtain kernel version for kernel header
  # installation on ubuntu and debian
  kernel_ver = node["kernel"]["release"]
  package "linux-headers-#{kernel_ver}" do
    options platform_options["package_overrides"]
    action :install
  end

end

directory "/var/run/openvswitch" do
  recursive true
  owner node["openstack"]["network"]["platform"]["user"]
  group node["openstack"]["network"]["platform"]["group"]
  mode 00755
  action :create
end


platform_options["quantum_openvswitch_packages"].each do |pkg|
  package pkg do
    action :install
  end
end

# The current openvswitch package of centos 6.4 cannot create GRE tunnel successfully
# The centos 6.4 kernel version is 2.6.32-358.18.1.el6.x86_64
# This code block was deperated because the ovs package was updated.
#if platform?(%w(fedora redhat centos))
#  remote_directory "/tmp/openvswitch" do
#    source "openvswitch"
#    files_owner "root"
#    files_group "root"
#    mode "0644"
#    recursive true
#    action :create
#  end
  
#  execute "update openvswitch package" do
#    ignore_failure true
#    command "chmod +x /tmp/openvswitch/install.sh; sh /tmp/openvswitch/install.sh"
#    action :run
#  end  
#end

service "quantum-server" do
  service_name node["openstack"]["network"]["platform"]["quantum_server_service"]
  supports :status => true, :restart => true
  action :nothing
end

service "quantum-openvswitch-switch" do
  service_name platform_options["quantum_openvswitch_service"]
  supports :status => true, :restart => true
  action :restart
end


service "quantum-server" do
  service_name platform_options["quantum_server_service"]
  supports :status => true, :restart => true
  ignore_failure true
  action :nothing
end

platform_options["quantum_openvswitch_agent_packages"].each do |pkg|
  package pkg do
    action :install
    options platform_options["package_overrides"]
  end
end

service "quantum-plugin-openvswitch-agent" do
  service_name platform_options["quantum_openvswitch_agent_service"]
  supports :status => true, :restart => true
  action [ :enable, :restart ]
end

execute "chkconfig openvswitch on" do
  only_if { platform?(%w(fedora redhat centos)) } 
end

execute "quantum-node-setup --plugin openvswitch" do
  only_if { platform?(%w(fedora redhat centos)) } # :pragma-foodcritic: ~FC024 - won't fix this
  notifies :run, "execute[delete_auto_qpid]", :immediately
end

if not ["nicira", "plumgrid", "bigswitch"].include?(main_plugin)
  int_bridge = node["openstack"]["network"]["openvswitch"]["integration_bridge"]
  execute "create internal network bridge" do
    ignore_failure true
    command "ovs-vsctl add-br #{int_bridge}"
    action :run
    not_if "ovs-vsctl show | grep 'Bridge #{int_bridge}'"
    notifies :restart, "service[quantum-plugin-openvswitch-agent]", :delayed
  end
end

if not ["nicira", "plumgrid", "bigswitch"].include?(main_plugin)
  if node["openstack"]["network"]["openvswitch"]["tenant_network_type"] == 'gre'
    tun_bridge = node["openstack"]["network"]["openvswitch"]["tunnel_bridge"]
    execute "create tunnel network bridge" do
      ignore_failure true
      command "ovs-vsctl add-br #{tun_bridge}"
      action :run
      not_if "ovs-vsctl show | grep '#{tun_bridge}'"
      notifies :restart, "service[quantum-plugin-openvswitch-agent]", :delayed
    end
  end
    
  if node["openstack"]["network"]["openvswitch"]["tenant_network_type"] == 'vlan'
    ethernet=node['openstack']['networking']['tenant']['interface']
    bridge_mappings = node["openstack"]["network"]["openvswitch"]["bridge_mappings"]
    bridge = bridge_mappings.split(":").map(&:strip).reject(&:empty?)[1]
    execute "create tunnel network bridge" do
      ignore_failure true
      command "ovs-vsctl add-br #{bridge};ovs-vsctl add-port #{bridge} #{ethernet}"
      action :run
      not_if "ovs-vsctl show | grep '#{bridge}'"
      notifies :restart, "service[quantum-plugin-openvswitch-agent]", :delayed
    end
   end        
end

if node['openstack']['network']['disable_offload']

  package "ethtool" do
    action :install
    options platform_options["package_overrides"]
  end

  service "disable-eth-offload" do
    supports :restart => false, :start => true, :stop => false, :reload => false
    priority({ 2 => [ :start, 19 ]})
    action :nothing
  end

  # a priority of 19 ensures we start before openvswitch
  # at least on ubuntu and debian
  cookbook_file "disable-eth-offload-script" do
    path "/etc/init.d/disable-eth-offload"
    source "disable-eth-offload.sh"
    owner "root"
    group "root"
    mode "0755"
    notifies :enable, "service[disable-eth-offload]"
    notifies :start, "service[disable-eth-offload]"
  end
end

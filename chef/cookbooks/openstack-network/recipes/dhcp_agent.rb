#
# Cookbook Name:: openstack-network
# Recipe:: dhcp_agent
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

include_recipe "openstack-network::common"

platform_options = node["openstack"]["network"]["platform"]
driver_name = node["openstack"]["network"]["interface_driver"].split('.').last.downcase
main_plugin = node["openstack"]["network"]["interface_driver_map"][driver_name]

platform_options["quantum_dhcp_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]
    action :install
  end
end

service "quantum-dhcp-agent" do
  service_name platform_options["quantum_dhcp_agent_service"]
  supports :status => true, :restart => true

  action :enable
end

# Some plugins have DHCP functionality, so we install the plugin
# Python package and include the plugin-specific recipe here...
package platform_options["quantum_plugin_package"].gsub("%plugin%", main_plugin) do
  options platform_options["package_overrides"]
  action :install
  # plugins are installed by the main openstack-quantum package on SUSE
  not_if { platform_family? "suse" }
end

#execute "quantum-dhcp-setup --plugin #{main_plugin}" do
#  notifies :run, "execute[delete_auto_qpid]", :immediately
#  only_if { platform?(%w(fedora redhat centos)) } # :pragma-foodcritic: ~FC024 - won't fix this
#end

template "/etc/quantum/dnsmasq.conf" do
  source "dnsmasq.conf.erb"
  owner node["openstack"]["network"]["platform"]["user"]
  group node["openstack"]["network"]["platform"]["group"]
  mode   00644
  notifies :restart, "service[quantum-dhcp-agent]", :delayed
end

template "/etc/quantum/dhcp_agent.ini" do
  source "dhcp_agent.ini.erb"
  owner node["openstack"]["network"]["platform"]["user"]
  group node["openstack"]["network"]["platform"]["group"]
  mode   00644
  notifies :restart, "service[quantum-dhcp-agent]", :immediately
end

# Deal with ubuntu precise dnsmasq 2.59 version by custom
# compiling a more recent version of dnsmasq
#
# See:
# https://lists.launchpad.net/openstack/msg11696.html
# https://bugs.launchpad.net/ubuntu/+source/dnsmasq/+bug/1013529
# https://bugs.launchpad.net/ubuntu/+source/dnsmasq/+bug/1103357
# http://www.thekelleys.org.uk/dnsmasq/CHANGELOG (SO_BINDTODEVICE)
#
# Would prefer a PPA or backport but there are none and upstream
# has no plans to fix
if node['lsb'] && node['lsb']['codename'] == "precise"

  platform_options["quantum_dhcp_build_packages"].each do |pkg|
    package pkg do
      action :install
    end
  end

  dhcp_options = node['openstack']['network']['dhcp']

  src_filename = dhcp_options['dnsmasq_filename']
  src_filepath = "#{Chef::Config['file_cache_path']}/#{src_filename}"
  extract_path = "#{Chef::Config['file_cache_path']}/#{dhcp_options['dnsmasq_checksum']}"

  remote_file src_filepath do
    source dhcp_options['dnsmasq_url']
    checksum dhcp_options['dnsmasq_checksum']
    owner 'root'
    group 'root'
    mode 00644
  end

  bash 'extract_package' do
    cwd ::File.dirname(src_filepath)
    code <<-EOH
      mkdir -p #{extract_path}
      tar xzf #{src_filename} -C #{extract_path}
      mv #{extract_path}/*/* #{extract_path}/
      cd #{extract_path}/
      echo '2.65' > VERSION
      debian/rules binary
      EOH
    not_if { ::File.exists?(extract_path) }
    notifies :install, "dpkg_package[dnsmasq-utils]", :immediately
    notifies :install, "dpkg_package[dnsmasq-base]", :immediately
    notifies :install, "dpkg_package[dnsmasq]", :immediately
  end

  dpkg_package "dnsmasq-utils" do
    source "#{extract_path}/../dnsmasq-utils_#{dhcp_options['dnsmasq_dpkgversion']}_#{dhcp_options['dnsmasq_architecture']}.deb"
    action :nothing
  end
  dpkg_package "dnsmasq-base" do
    source "#{extract_path}/../dnsmasq-base_#{dhcp_options['dnsmasq_dpkgversion']}_#{dhcp_options['dnsmasq_architecture']}.deb"
    action :nothing
  end
  dpkg_package "dnsmasq" do
    source "#{extract_path}/../dnsmasq_#{dhcp_options['dnsmasq_dpkgversion']}_all.deb"
    action :nothing
  end

end

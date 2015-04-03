#
# Cookbook Name:: keepalived
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
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

require 'chef/util/file_edit'

# The following code block is trying to automaticly elect master node
# however it is not polished very well, currently only support two keepalived
# nodes. If you are going to build a keepalived cluster with 3 and up nodes,
# either poilish it or use your own recipe to handle the situation.
master_node = keepalived_master('os-ha', 'keepalived_default_master')
instance = node.set['keepalived']['instances']['openstack']
router_ids = node.set['keepalived']['global']['router_ids']
if node.name.eql?(master_node.name)
  if instance['states']["#{node.name}"].empty?
    router_ids["#{node.name}"] = 'lsb01'
    instance['priorities']["#{node.name}"] = '110'
    instance['states']["#{node.name}"] = 'MASTER'
  end
else
  if instance['states']["#{node.name}"].empty?
    router_ids["#{node.name}"] = 'lsb02'
    instance['priorities']["#{node.name}"] = '101'
    instance['states']["#{node.name}"] = 'BACKUP'
  end
end

case node["platform_family"]
when "debian"
  execute "apt-update" do
    user "root"
    command "apt-get -y update"
    action :run
  end

  execute "apt-upgrade" do
    user "root"
    command "apt-get -y upgrade"
    action :run
  end
end

if node['platform_family'] == 'suse'
  node.default['keepalived']['use_distro_version'] = false
  node.default['keepalived']['rpm_package_url']  = "http://download.opensuse.org/repositories/home:/H4T:/network:/ha-clustering/SLE_11_SP3/x86_64/keepalived-1.2.7-7.1.x86_64.rpm"
  package "src_vipa"
end
 
if node['keepalived']['use_distro_version'] or (not node['local_repo'].nil? and not node['local_repo'].empty?)
  package "keepalived"
else
  rpm_package = node['keepalived']['rpm_package_url']
  if rpm_package
    if not node['proxy_url'].nil? and not node['proxy_url'].empty?
      execute "download_keepalived" do
        command "wget #{rpm_package}"
        cwd Chef::Config['file_cache_path']
        not_if { ::File.exists?(::File.basename(rpm_package)) }
        environment ({ 'http_proxy' =>  node['proxy_url'], 'https_proxy' => node['proxy_url'] })
      end  
    else
      remote_file "#{Chef::Config[:file_cache_path]}/#{::File.basename(rpm_package)}" do
        source rpm_package
        action :create_if_missing
      end
    end
    rpm_package "#{Chef::Config[:file_cache_path]}/#{::File.basename(rpm_package)}"
  end
end

if node['keepalived']['shared_address']
  case node['platform_family']
  when "debian"
    file '/etc/sysctl.d/60-ip-nonlocal-bind.conf' do
      mode 0644
      content "net.ipv4.ip_nonlocal_bind=1\n"
    end

    service 'procps' do
      action :start
    end

  when "rhel"
    ruby_block "update sysctl" do
      block do
        fe = Chef::Util::FileEdit.new('/etc/sysctl.conf')
        fe.search_file_delete_line(/^net.ipv4.ip_nonlocal_bind\s*=\s*0/)
        fe.insert_line_if_no_match(/^net.ipv4.ip_nonlocal_bind\s*=s*1/,
                                   "net.ipv4.ip_nonlocal_bind = 1")
        fe.write_file
      end
      not_if %Q|grep "^net.ipv4.ip_nonlocal_bind[[:space:]]*=[[:space:]]*1" /etc/sysctl.conf|
      notifies :run, "execute[apply sysctl]", :immediately
    end

    execute "apply sysctl" do
      command "sysctl -p"
      action :nothing
    end
  end
end

template "keepalived.conf" do
  path "/etc/keepalived/keepalived.conf"
  source "keepalived.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

service "keepalived" do
  supports :restart => true
  action [:enable, :start]
  subscribes :restart, "template[keepalived.conf]"
end

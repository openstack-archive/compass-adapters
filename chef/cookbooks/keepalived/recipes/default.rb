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

defaultbag = "openstack"
if !Chef::DataBag.list.key?(defaultbag)
  Chef::Application.fatal!("databag '#{defaultbag}' doesn't exist.")
  return
end

myitem = node.attribute?('cluster')? node['cluster']:"env_default"

if !search(defaultbag, "id:#{myitem}")
  Chef::Application.fatal!("databagitem '#{myitem}' doesn't exist.")
  return
end

mydata = data_bag_item(defaultbag, myitem)

if mydata['ha']['status'].eql?('enable')
  mydata['ha']['keepalived']['router_ids'].each do |nodename, routerid|
    node.override['keepalived']['global']['router_ids']["#{nodename}"] = routerid
  end

  mydata['ha']['keepalived']['instance_name']['priorities'].each do |nodename, priority|
    node.override['keepalived']['instances']['openstack']['priorities']["#{nodename}"] = priority
  end

  mydata['ha']['keepalived']['instance_name']['states'].each do |nodename, status|
    node.override['keepalived']['instances']['openstack']['states']["#{nodename}"] = status
  end

  interface = node['keepalived']['instances']['openstack']['interface']
  print "\n node['keepalived']['instances']['openstack']['interface'] = #{node['keepalived']['instances']['openstack']['interface']}"
  node.override['keepalived']['instances']['openstack']['ip_addresses'] = [
          "#{mydata['ha']['keepalived']['instance_name']['vip']} dev #{interface}" ]
end

package "keepalived"

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
    template "/etc/sysctl.conf" do
      source "sysctl.conf.erb"
      owner "root"
      group "root"
      mode 00644
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

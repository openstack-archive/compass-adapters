#
# Cookbook Name:: ganglia
# Recipe:: default
#
# Copyright 2011, Heavy Water Software Inc.
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

case node['platform']
when "ubuntu", "debian"
  package "ganglia-monitor"
when "redhat", "centos", "fedora"
  include_recipe "ganglia::source"

  execute "copy ganglia-monitor init script" do
    command "cp " +
      "/usr/src/ganglia-#{node['ganglia']['version']}/gmond/gmond.init " +
      "/etc/init.d/ganglia-monitor"
    not_if "test -f /etc/init.d/ganglia-monitor"
  end

  user "ganglia"
end

directory "/etc/ganglia"

# figure out which cluster(s) we should join
# this section assumes you can send to multiple ports.
ports=[]
clusternames = []
node['ganglia']['host_cluster'].each do |k,v|
  if (v == 1 and node['ganglia']['clusterport'].has_key?(k))
    ports.push(node['ganglia']['clusterport'][k])
    clusternames.push(k)
  end
end
if ports.empty?
  ports.push(node['ganglia']['clusterport']['default'])
  clusternames.push('default')
end

case node['ganglia']['unicast']
when true
  # fill in the gmond collectors by attribute if it exists, search if you find anything, or localhost.
  gmond_collectors = []
  if node['ganglia']['server_host']
    gmond_collectors = [node['ganglia']['server_host']]
  elsif gmond_collectors.empty?
    gmond_collectors = search(:node, "role:#{node['ganglia']['server_role']} AND chef_environment:#{node.chef_environment}").map {|node| node['ipaddress']}
  end rescue NoMethodError
  if gmond_collectors.empty?
     gmond_collectors = ["127.0.0.1"]
  end

  template "/etc/ganglia/gmond.conf" do
    source "gmond_unicast.conf.erb"
    variables( :cluster_name => clusternames[0],
               :gmond_collectors => gmond_collectors,
               :ports => ports,
               :spoof_hostname => node['ganglia']['spoof_hostname'],
               :hostname => node.hostname )
    notifies :restart, "service[ganglia-monitor]"
  end
when false
  template "/etc/ganglia/gmond.conf" do
    source "gmond.conf.erb"
    variables( :cluster_name => clusternames[0],
               :ports => ports )
    notifies :restart, "service[ganglia-monitor]"
  end
end

service "ganglia-monitor" do
  pattern "gmond"
  supports :restart => true
  action [ :enable, :start ]
end

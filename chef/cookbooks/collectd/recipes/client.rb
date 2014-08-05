#
# Cookbook Name:: collectd
# Recipe:: client
#
# Copyright 2010, Atari, Inc
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

include_recipe "collectd"

#servers = []
#search(:node, 'recipes:collectd\\:\\:server') do |n|
#  servers << n['fqdn']
#end

#if servers.empty?
#  raise "No servers found. Please configure at least one node with collectd::server."
#end

#collectd_plugin "network" do
#  options :server=>servers
#end

cookbook_file "#{node['collectd']['plugin_dir']}/kairosdb_writer.py" do
  source "kairosdb_writer.py"
  owner "root"
  group "root"
  mode 00644
  notifies :restart, "service[collectd]"
  action :create_if_missing
end

case node["platform_family"]
when "rhel"
  node.override["collectd"]["plugins"]=node["collectd"]["rhel"]["plugins"].to_hash
when "debian"
  node.override["collectd"]["plugins"]=node["collectd"]["debian"]["plugins"].to_hash
end

node["collectd"]["plugins"].each_pair do |plugin_key, options|
  collectd_plugin plugin_key do
    options  options
  end
end

collectd_python_plugin "kairosdb_writer" do
  opts  =    {"KairosDBHost"=>node['collectd']['server']['host'],
              "KairosDBPort"=>node['collectd']['server']['port'],
              "KairosDBProtocol"=>node['collectd']['server']['protocol'],
              "LowercaseMetricNames"=>"true",
              "Tags" => "host=#{node['fqdn']}\" \"role=OSROLE\" \"location=China.Beijing.TsingHua\" \"cluster=#{node['cluster']}",
              "TypesDB" => node['collectd']['types_db']
             }
  options(opts)         
end

#
# Cookbook Name:: collectd
# Recipe:: kairosdb
#
# Copyright 2014, Huawei Technologies, Co,ltd
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
cookbook_file "#{node['collectd']['plugin_dir']}/kairosdb_writer.py" do
  source "kairosdb_writer.py"
  owner "root"
  group "root"
  mode 00644
  action :create_if_missing
  notifies :restart, resources(:service => "collectd")
end

cluster_id = 'no_cluster_defined'
if node['compass'] and node['compass']['cluster_id']
  cluster_id = node['compass']['cluster_id']
end

if node['fqdn']
  node.set['collectd']['client']['fqdn'] = node['fqdn']
elsif node['hostname']
  node.set['collectd']['client']['fqdn'] = node['hostname']
elsif node['ipaddress']
  node.set['collectd']['client']['fqdn'] = node['ipaddress']
else
  node.set['collectd']['client']['fqdn'] = "fqdn_unknown"
end

collectd_python_plugin "kairosdb_writer" do
  opts  =    {"KairosDBHost"=>node['collectd']['server']['host'],
              "KairosDBPort"=>node['collectd']['server']['port'],
              "KairosDBProtocol"=>node['collectd']['server']['protocol'],
              "Tags" => "host=#{node['fqdn']}\" \"role=OSROLE\" \"location=China.Beijing.TsingHua\" \"cluster=#{cluster_id}",
              "TypesDB" => node['collectd']['types_db'],
             }
  options(opts)
end

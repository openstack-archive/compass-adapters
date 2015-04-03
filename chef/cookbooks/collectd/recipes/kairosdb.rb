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

if node['platform_family'] != 'suse'
  cookbook_file "#{node['collectd']['plugin_dir']}/kairosdb_writer.py" do
    source "kairosdb_writer.py"
    owner "root"
    group "root"
    mode 00644
    action :create_if_missing
    notifies :restart, resources(:service => "collectd")
  end

  if ! node['cluster']
    node.set['cluster'] = "no_cluster_defined"
  end

  node.set['collectd']['client']['fqdn'] = node['fqdn'] || node['hostname'] || node['ipaddress'] || "fqdn_unknown"

  collectd_python_plugin "kairosdb_writer" do
    opts  =    {"KairosDBHost"=>node['collectd']['server']['host'],
                "KairosDBPort"=>node['collectd']['server']['port'],
                "KairosDBProtocol"=>node['collectd']['server']['protocol'],
                "Tags" => "host=#{node['fqdn']}\" \"role=OSROLE\" \"location=China.Beijing.TsingHua\" \"cluster=#{node['cluster']}",
                "TypesDB" => node['collectd']['types_db'],
                "LowercaseMetricNames"=>"true"
               }
    options(opts)
  end
end

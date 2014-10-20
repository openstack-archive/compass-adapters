#
# Cookbook Name:: collectd-plugins
# Recipe:: rabbitmq
#
# Copyright 2012, Rackspace Hosting, Inc
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

package "python-requests" do
  action :install
end

cookbook_file File.join(node['collectd']['plugin_dir'], "rabbitmq_info.py") do
  source "rabbitmq_info.py"
  owner "root"
  group "root"
  mode "0755"
  notifies :restart, resources(:service => "collectd")
end

node.override["collectd"]["mq"]["vhost"] = node["openstack"]["mq"]["vhost"]

collectd_python_plugin "rabbitmq_info" do
  opts = { "Vhost" => node["collectd"]["mq"]["vhost"],
           "Api" => "http://localhost:15672/api/queues",
           "User" => "#{node["openstack"]["mq"]["user"]}",
           "Pass" => "#{node["openstack"]["mq"]["password"]}"
         }
  options(opts)
end

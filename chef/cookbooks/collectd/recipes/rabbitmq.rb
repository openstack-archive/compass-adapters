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

cookbook_file File.join(node['collectd']['plugin_dir'], "rabbitmq_info.py") do
  source "rabbitmq_info.py"
  owner "root"
  group "root"
  mode "0755"
  notifies :restart, resources(:service => "collectd")
end

node.override["collectd"]["mq"]["vhost"] = mydata["mq"]["rabbitmq"]["vhost"]

collectd_python_plugin "rabbitmq_info" do
  opts = { "Vhost" => node["collectd"]["mq"]["vhost"],
           "Api" => "http://localhost:15672/api/queues",
           "UserPass" => "#{mydata["credential"]["mq"]["rabbitmq"]["username"]}:#{mydata["credential"]["mq"]["rabbitmq"]["password"]}"
         }
  options(opts)
end

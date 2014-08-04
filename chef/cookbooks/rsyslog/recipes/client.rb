#
# Cookbook Name:: rsyslog
# Recipe:: client
#
# Copyright 2009-2011, Opscode, Inc.
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

include_recipe "rsyslog"
roles="#{node[:roles]}"

package "dstat" do
  action :install
end

execute "dstat" do
  command "dstat -tcmndp --top-cpu >>/var/log/dstat.log &"
  action :run
end

if roles.gsub("\n",",").strip =~ /os-ops-messaging/
  case node["platform_family"]
  when "debian"
    node.force_override['rsyslog']['debianloglist']['rabbitmq']="/var/log/rabbitmq/rabbit\@#{node['hostname']}.log"
  when "rhel"
    node.force_override['rsyslog']['rhelloglist']['rabbitmq']="/var/log/rabbitmq/rabbit\@#{node['hostname']}.log"
  end
end

template "/etc/rsyslog.d/openstack.conf" do
  source "openstack.conf.erb"
  backup false
  owner "root"
  group "root"
  mode 0644
  case node["platform_family"]
  when "debian"
      variables :loglist => node['rsyslog']['debianloglist']
  when "rhel"
      variables :loglist => node['rsyslog']['rhelloglist']
  end
  notifies :restart, "service[rsyslog]"
end

file "/etc/rsyslog.d/server.conf" do
  action :delete
  notifies :reload, "service[rsyslog]"
  only_if do ::File.exists?("/etc/rsyslog.d/server.conf") end
end

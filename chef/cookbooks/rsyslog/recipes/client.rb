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

if roles.gsub("\n",",").strip =~ /os-compute/
  template "/etc/rsyslog.d/nova.conf" do
    source "openstack.conf.erb"
    backup false
    owner "root"
    group "root"
    mode 0644
    case node["platform_family"]
    when "debian"
        variables :loglist => node['rsyslog']['debiannovalog']
    when "rhel"
        variables :loglist => node['rsyslog']['novalog']
    end
    notifies :restart, "service[rsyslog]"
  end
end
if roles.gsub("\n",",").strip =~ /os-identity/
  template "/etc/rsyslog.d/keystone.conf" do
    source "openstack.conf.erb"
    backup false
    owner "root"
    group "root"
    mode 0644
    variables :loglist => node['rsyslog']['keystonelog']
    notifies :restart, "service[rsyslog]"
  end
end
if roles.gsub("\n",",").strip =~ /os-image/
  template "/etc/rsyslog.d/glance.conf" do
    source "openstack.conf.erb"
    backup false
    owner "root"
    group "root"
    mode 0644
    variables :loglist => node['rsyslog']['glancelog']
    notifies :restart, "service[rsyslog]"
  end
end
if roles.gsub("\n",",").strip =~ /os-block-storage/
  template "/etc/rsyslog.d/cinder.conf" do
    source "openstack.conf.erb"
    backup false
    owner "root"
    group "root"
    mode 0644
    case node["platform_family"]
    when "debian"
        variables :loglist => node['rsyslog']['debiancinderlog']
    when "rhel"
        variables :loglist => node['rsyslog']['cinderlog']
    end
    notifies :restart, "service[rsyslog]"
  end
end
if roles.gsub("\n",",").strip =~ /os-network/
  template "/etc/rsyslog.d/quantum.conf" do
    source "openstack.conf.erb"
    backup false
    owner "root"
    group "root"
    mode 0644
    variables :loglist => node['rsyslog']['quantumlog']
    notifies :restart, "service[rsyslog]"
  end
end
if roles.gsub("\n",",").strip =~ /os-ops-messaging/
  template "/etc/rsyslog.d/messaging.conf" do
    source "openstack.conf.erb"
    backup false
    owner "root"
    group "root"
    mode 0644
    variables :loglist => node['rsyslog']['messaginglog']
    notifies :restart, "service[rsyslog]"
  end
end
if roles.gsub("\n",",").strip =~ /os-ops-database/
  template "/etc/rsyslog.d/database.conf" do
    source "openstack.conf.erb"
    backup false
    owner "root"
    group "root"
    mode 0644
    case node["platform_family"]
    when "debian"
        variables :loglist => node['rsyslog']['debianmysqllog']
    when "rhel"
        variables :loglist => node['rsyslog']['mysqllog']
    end
    notifies :restart, "service[rsyslog]"
  end
end

template "/etc/rsyslog.d/sysstat.conf" do
  source "openstack.conf.erb"
  backup false
  owner "root"
  group "root"
  mode 0644
  variables :loglist => node['rsyslog']['sysstatlog']
  notifies :restart, "service[rsyslog]", :immediately
end

file "/etc/rsyslog.d/server.conf" do
  action :delete
  notifies :reload, "service[rsyslog]"
  only_if do ::File.exists?("/etc/rsyslog.d/server.conf") end
end

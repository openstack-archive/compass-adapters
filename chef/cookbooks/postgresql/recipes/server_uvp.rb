#
# Cookbook Name:: postgresql
# Recipe:: server
#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
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

include_recipe "postgresql::client"

# Create a group and user like the package will.
# Otherwise the templates fail.

directory node['postgresql']['dir'] do
  owner node['postgresql']['user']
  group node['postgresql']['group']
  recursive true
  action :create
end

node['postgresql']['server']['packages'].each do |pg_pack|

  package pg_pack

end

directory "/opt/gaussdb/app" do
  owner node['postgresql']['user']
  group node['postgresql']['group']
  mode 0755
  action :create
end

execute "add gaussdb lib into library path" do
  command "sed -i '1i /opt/gaussdb/app/lib' /etc/ld.so.conf; ldconfig"
  action :run
  not_if "grep /opt/gaussdb/app/lib /etc/ld.so.conf"
end

directory "/var/run/postgresql" do
  action :create
  group node['postgresql']['group']
  owner node['postgresql']['user']
  mode '0755'
end

template "/etc/init.d/gaussdb" do
  source "gaussdb.erb"
  owner "root"
  group "root"
  mode 00755
end

template 'home/gaussdba/.bashrc' do
  source "gaussdba.bashrc.erb"
  owner node['postgresql']['user']
  group node['postgresql']['group']
  mode 00644
end

execute "/usr/bin/initdb #{node['postgresql']['initdb_locale']}" do
  command "./gs_initdb --locale=en_US.UTF-8 --auth=\"ident\" #{node['postgresql']['dir']} --pwpasswd=#{node['postgresql']['password']['postgres']}"
  user node['postgresql']['user']
  group node['postgresql']['group']
  cwd '/opt/gaussdb/app/bin'
  action :run
  not_if { ::File.exist?(File.join(node['postgresql']['dir'], "PG_VERSION")) }
end

template "/etc/sysconfig/postgresql" do
  source "postgresql.sysconfig.erb"
  mode "0644"
  notifies :restart, "service[#{node['postgresql']['server']['service_name']}]", :delayed
end

template "#{node['postgresql']['dir']}/postgresql.conf" do
  source "postgresql.conf.erb"
  owner node['postgresql']['user']
  group node['postgresql']['group']
  mode 0600
  notifies :restart, "service[#{node['postgresql']['server']['service_name']}]", :delayed
end

template "#{node['postgresql']['dir']}/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner node['postgresql']['user']
  group node['postgresql']['group']
  mode 00600
  notifies :restart, "service[#{node['postgresql']['server']['service_name']}]", :delayed
end

service "gaussdb" do
  service_name node['postgresql']['server']['service_name']
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end



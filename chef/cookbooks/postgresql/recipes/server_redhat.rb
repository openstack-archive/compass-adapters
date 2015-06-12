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

group node['postgresql']['group'] do
  gid 26
end

user node['postgresql']['user'] do
  shell "/bin/bash"
  comment "PostgreSQL Server"
  home "/var/lib/pgsql"
  gid "#{node['postgresql']['group']}"
  system true
  uid 26
  supports :manage_home => false
end

directory node['postgresql']['dir'] do
  owner node['postgresql']['user']
  group node['postgresql']['group']
  recursive true
  action :create
end

node['postgresql']['server']['packages'].each do |pg_pack|

  package pg_pack

end

template "/etc/sysconfig/pgsql/#{node['postgresql']['server']['service_name']}" do
  source "pgsql.sysconfig.erb"
  mode "0644"
  notifies :restart, "service[#{node['postgresql']['server']['service_name']}]", :delayed
end

execute "/sbin/service #{node['postgresql']['server']['service_name']} initdb #{node['postgresql']['initdb_locale']}" do
  not_if { ::File.exist?(File.join(node['postgresql']['dir'], "PG_VERSION")) }
end

service node['postgresql']['server']['service_name'] do
  service_name node['postgresql']['server']['service_name']
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end

change_notify = node['postgresql']['server']['config_change_notify']

template "#{node['postgresql']['dir']}/postgresql.conf" do
  source "postgresql.conf.erb"
  owner node['postgresql']['user']
  group node['postgresql']['group']
  mode 0600
  notifies change_notify, "service[#{node['postgresql']['server']['service_name']}]", :immediately
end

template "#{node['postgresql']['dir']}/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner node['postgresql']['user']
  group node['postgresql']['group']
  mode 00600
  notifies change_notify, "service[#{node['postgresql']['server']['service_name']}]", :immediately
end

# NOTE: Consider two facts before modifying "assign-postgres-password":
# (1) Passing the "ALTER ROLE ..." through the psql command only works
#     if passwordless authorization was configured for local connections.
#     For example, if pg_hba.conf has a "local all postgres ident" rule.
# (2) It is probably fruitless to optimize this with a not_if to avoid
#     setting the same password. This chef recipe doesn't have access to
#     the plain text password, and testing the encrypted (md5 digest)
#     version is not straight-forward.
bash "assign-postgres-password" do
  user node['postgresql']['user']
  code <<-EOH
echo "ALTER ROLE postgres ENCRYPTED PASSWORD '#{node['postgresql']['password']['postgres']}';" | psql
  EOH
  action :run
end

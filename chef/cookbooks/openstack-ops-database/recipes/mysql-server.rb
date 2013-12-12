#
# Cookbook Name:: openstack-ops-database
# Recipe:: mysql-server
#
# Copyright 2013, Opscode, Inc.
# Copyright 2012-2013, Rackspace US, Inc.
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

# override default attributes in the upstream mysql cookbook
node.set['mysql']['bind_address'] = node['openstack']['db']['bind_address']
node.set['mysql']['server_debian_password'] = node['openstack']['db']['super']['password']
node.set['mysql']['server_root_password']   = node['openstack']['db']['super']['password']
node.set['mysql']['server_repl_password']   = node['openstack']['db']['super']['password']
  
node.set['mysql']['tunable']['innodb_thread_concurrency']       = "0"
node.set['mysql']['tunable']['innodb_commit_concurrency']       = "0"
node.set['mysql']['tunable']['innodb_read_io_threads']          = "4"
node.set['mysql']['tunable']['innodb_flush_log_at_trx_commit']  = "2"

node.save

include_recipe "openstack-ops-database::mysql-client"
include_recipe "mysql::server"

mysql_connection_info = {:host => "localhost",
                         :username => 'root',
                         :password => node['mysql']['server_root_password']}

# removing insecure default mysql users
mysql_database_user 'drop empty localhost user' do
  username ''
  host 'localhost'
  connection mysql_connection_info
  action :drop
end

# removing insecure default mysql users
mysql_database_user 'drop empty hostname user' do
  username ''
  host "#{node.hostname}"
  connection mysql_connection_info
  action :drop
end

# drop the test database
mysql_database 'test' do
  connection mysql_connection_info
  action :drop
end

# flush the privileges
mysql_database "FLUSH privileges" do
  connection mysql_connection_info
  sql "FLUSH privileges"
  action :nothing
  subscribes :query, "mysql_database[test]"
end

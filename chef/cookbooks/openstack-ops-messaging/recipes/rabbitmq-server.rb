# encoding: UTF-8
#
# Cookbook Name:: openstack-ops-messaging
# Recipe:: rabbitmq-server
#
# Copyright 2013, Opscode, Inc.
# Copyright 2013, AT&T Services, Inc.
# Copyright 2013, Craig Tracey <craigtracey@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

user = node['openstack']['mq']['user']
password = node['openstack']['mq']['password']
pass = get_password 'user', user, password

vhost = node['openstack']['mq']['vhost']
rabbit_endpoint = endpoint 'mq'
listen_address = rabbit_endpoint.host

# Used by OpenStack#rabbit_servers/#rabbit_server
node.set['openstack']['mq']['listen'] = listen_address

node.override['rabbitmq']['port'] = rabbit_endpoint.port
node.override['rabbitmq']['address'] = listen_address
node.override['rabbitmq']['default_user'] = user
node.override['rabbitmq']['default_pass'] = pass

# Clustering
if node['openstack']['mq']['cluster']
  node.override['rabbitmq']['cluster'] = node['openstack']['mq']['cluster']
  node.override['rabbitmq']['erlang_cookie'] = get_password 'service', 'rabbit_cookie'
  qs = "roles:#{node['openstack']['mq']['server_role']} AND chef_environment:#{node.chef_environment}"
  node.override['rabbitmq']['cluster_disk_nodes'] = search(:node, qs).map do |n|
    "#{user}@#{n['hostname']}"
  end.sort
end

include_recipe 'rabbitmq'
include_recipe 'rabbitmq::mgmt_console'

rabbitmq_user 'remove rabbit guest user' do
  user 'guest'
  action :delete

  not_if { user == 'guest' }
end

rabbitmq_user 'add openstack rabbit user' do
  user user
  password pass

  action :add
end

rabbitmq_user 'change openstack rabbit user password' do
  user user
  password pass

  action :change_password
end

rabbitmq_vhost 'add openstack rabbit vhost' do
  vhost vhost

  action :add
end

rabbitmq_user 'set openstack user permissions' do
  user user
  vhost vhost
  permissions '.* .* .*'
  action :set_permissions
end

# Necessary for graphing.
rabbitmq_user 'set rabbit administrator tag' do
  user user
  tag 'administrator'

  action :set_tags
end

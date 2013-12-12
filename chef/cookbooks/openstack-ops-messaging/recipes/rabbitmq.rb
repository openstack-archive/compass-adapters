#
# Cookbook Name:: openstack-ops-messaging
# Recipe:: rabbitmq
#
# Copyright 2013, Opscode, Inc.
# Copyright 2012, John Dewey
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

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

node.set_unless['openstack']['messaging']['password'] = secure_password
node.set_unless['rabbitmq']['address'] = '0.0.0.0'
node.set_unless['rabbitmq']['port'] = 5672

include_recipe "rabbitmq"
include_recipe "rabbitmq::mgmt_console"

user = node['openstack']['messaging']['user']
vhost = node['openstack']['messaging']['vhost']

# remove the guest user
rabbitmq_user 'guest' do
  action :delete
  not_if { user.eql?('guest') }
end

rabbitmq_user user do
  password node['openstack']['messaging']['password']
  action :add
end

rabbitmq_vhost vhost do
  action :add
end

rabbitmq_user user do
  vhost vhost
  permissions ".* .* .*"
  action :set_permissions
end

# Necessary for graphing.
rabbitmq_user user do
  tag "administrator"
  action :set_tags
end

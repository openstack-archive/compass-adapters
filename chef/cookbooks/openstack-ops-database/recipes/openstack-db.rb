# encoding: UTF-8
#
# Cookbook Name:: openstack-ops-database
# Recipe:: openstack-db
#
# Copyright 2012-2013, AT&T Services, Inc.
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

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

db_create_with_user(
  'compute',
  node['openstack']['db']['compute']['username'],
  get_password('db', 'nova')
)

db_create_with_user(
  'dashboard',
  node['openstack']['db']['dashboard']['username'],
  get_password('db', 'horizon')
)

db_create_with_user(
  'identity',
  node['openstack']['db']['identity']['username'],
  get_password('db', 'keystone')
)

db_create_with_user(
  'image',
  node['openstack']['db']['image']['username'],
  get_password('db', 'glance')
)

db_create_with_user(
  'telemetry',
  node['openstack']['db']['telemetry']['username'],
  get_password('db', 'ceilometer')
)

db_create_with_user(
  'network',
  node['openstack']['db']['network']['username'],
  get_password('db', 'neutron')
)

db_create_with_user(
  'block-storage',
  node['openstack']['db']['block-storage']['username'],
  get_password('db', 'cinder')
)

db_create_with_user(
  'orchestration',
  node['openstack']['db']['orchestration']['username'],
  get_password('db', 'heat')
)

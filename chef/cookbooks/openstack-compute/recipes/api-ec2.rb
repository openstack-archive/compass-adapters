# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: api-ec2
#
# Copyright 2012, Rackspace US, Inc.
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

include_recipe 'openstack-compute::nova-common'

platform_options = node['openstack']['compute']['platform']

directory '/var/lock/nova' do
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode  00700

  action :create
end

# NOTE(mrodden): required for keystone auth middleware
package 'python-keystoneclient' do
  action :upgrade
end

platform_options['api_ec2_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']

    action :upgrade
  end
end

service 'nova-api-ec2' do
  service_name platform_options['api_ec2_service']
  supports status: true, restart: true
  subscribes :restart, resources('template[/etc/nova/nova.conf]')

  action :enable
end

identity_endpoint = endpoint 'identity-api'
identity_admin_endpoint = endpoint 'identity-admin'
service_pass = get_password 'service', node["openstack"]["compute"]["service_user"]

auth_uri = auth_uri_transform identity_endpoint.to_s, node['openstack']['compute']['api']['auth']['version']

template '/etc/nova/api-paste.ini' do
  source 'api-paste.ini.erb'
  owner  node['openstack']['compute']['user']
  group  node['openstack']['compute']['group']
  mode   00644
  variables(
    auth_uri: auth_uri,
    identity_admin_endpoint: identity_admin_endpoint,
    service_pass: service_pass
  )
  notifies :restart, 'service[nova-api-ec2]'
end

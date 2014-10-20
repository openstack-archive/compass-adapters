# encoding: UTF-8
#
# Cookbook Name:: openstack-object-storage
# Recipe:: swift-config-ceph
#
# Copyright 2014, Liucheng.
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

#create swift endpoint to ceph

require 'uri'

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

identity_admin_endpoint = endpoint 'identity-admin'

token = get_secret 'openstack_identity_bootstrap_token'
auth_url = ::URI.decode identity_admin_endpoint.to_s

swift_endpoint = "http://#{node['ceph']['radosgw domain']}/swift/v1"

service_pass = get_password 'service', 'openstack-object-storage'
service_tenant_name = 'service'
service_user = 'swift'
service_role = 'admin'
region = 'RegionOne'

# Register Image Service
openstack_identity_register 'Register Object Storage Service' do
  auth_uri auth_url
  bootstrap_token token
  service_name 'swift'
  service_type 'object-store'
  service_description 'Object Storage Service'

  action :create_service
end

# Register Image Endpoint
openstack_identity_register 'Register Object Storage Endpoint' do
  auth_uri auth_url
  bootstrap_token token
  service_type 'object-store'
  endpoint_region region
  endpoint_adminurl swift_endpoint
  endpoint_internalurl swift_endpoint
  endpoint_publicurl swift_endpoint

  action :create_endpoint
end

# Register Service Tenant
openstack_identity_register 'Register Service Tenant' do
  auth_uri auth_url
  bootstrap_token token
  tenant_name service_tenant_name
  tenant_description 'Service Tenant'
  tenant_enabled true # Not required as this is the default

  action :create_tenant
end

# Register Service User
openstack_identity_register "Register #{service_user} User" do
  auth_uri auth_url
  bootstrap_token token
  tenant_name service_tenant_name
  user_name service_user
  user_pass service_pass
  # String until https://review.openstack.org/#/c/29498/ merged
  user_enabled true

  action :create_user
end

## Grant Admin role to Service User for Service Tenant ##
openstack_identity_register "Grant '#{service_role}' Role to #{service_user} User for #{service_tenant_name} Tenant" do
  auth_uri auth_url
  bootstrap_token token
  tenant_name service_tenant_name
  user_name service_user
  role_name service_role

  action :grant_role
end


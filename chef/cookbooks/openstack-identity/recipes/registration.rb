#
# Cookbook Name:: openstack-identity
# Recipe:: setup
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2012-2013, Opscode, Inc.
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

require "uri"

class ::Chef::Recipe
  include ::Openstack
end

identity_admin_endpoint = endpoint "identity-admin"
identity_endpoint = endpoint "identity-api"

admin_tenant_name = node["openstack"]["identity"]["admin_tenant_name"]
admin_user = node["openstack"]["identity"]["admin_user"]
admin_pass = user_password node["openstack"]["identity"]["admin_password"]
auth_uri = ::URI.decode identity_admin_endpoint.to_s

bootstrap_token = secret "secrets", "#{node["openstack"]["identity"]["admin_token"]}"

# We need to bootstrap the keystone admin user so that calls
# to keystone_register will succeed, since those provider calls
# use the admin tenant/user/pass to get an admin token.
bash "bootstrap-keystone-admin" do
  # A shortcut bootstrap command was added to python-keystoneclient
  # in early Grizzly timeframe... but we need to do all the commands
  # here manually since the python-keystoneclient package included
  # in CloudArchive (for now) doesn't have it...
  insecure = node["openstack"]["auth"]["validate_certs"] ? "" : " --insecure"
  base_ks_cmd = "keystone#{insecure} --endpoint=#{auth_uri} --token=#{bootstrap_token}"
  code <<-EOF
set -x
function get_id () {
    echo `"$@" | grep ' id ' | awk '{print $4}'`
}
#{base_ks_cmd} tenant-list | grep #{admin_tenant_name}
if [[ $? -eq 1 ]]; then
  ADMIN_TENANT=$(get_id #{base_ks_cmd} tenant-create --name=#{admin_tenant_name})
else
  ADMIN_TENANT=$(#{base_ks_cmd} tenant-list | grep #{admin_tenant_name} | awk '{print $2}')
fi
#{base_ks_cmd} role-list | grep admin
if [[ $? -eq 1 ]]; then
  ADMIN_ROLE=$(get_id #{base_ks_cmd} role-create --name=admin)
else
  ADMIN_ROLE=$(#{base_ks_cmd} role-list | grep admin | awk '{print $2}')
fi
#{base_ks_cmd} user-list | grep #{admin_user}
if [[ $? -eq 1 ]]; then
  ADMIN_USER=$(get_id #{base_ks_cmd} user-create --name=#{admin_user} --pass="#{admin_pass}" --email=#{admin_user}@example.com)
else
  ADMIN_USER=$(#{base_ks_cmd} user-list | grep #{admin_user} | awk '{print $2}')
fi
#{base_ks_cmd} user-role-list --user-id=$ADMIN_USER --tenant-id=$ADMIN_TENANT | grep admin
if [[ $? -eq 1 ]]; then
  #{base_ks_cmd} user-role-add --user-id $ADMIN_USER --role-id $ADMIN_ROLE --tenant-id $ADMIN_TENANT
fi
exit 0
EOF
end

node["openstack"]["identity"]["tenants"].each do |tenant_name|
  ## Add openstack tenant ##
  openstack_identity_register "Register '#{tenant_name}' Tenant" do
    auth_uri auth_uri
    bootstrap_token bootstrap_token
    tenant_name tenant_name
    tenant_description "#{tenant_name} Tenant"
    tenant_enabled true # Not required as this is the default

    action :create_tenant
  end
end

node["openstack"]["identity"]["roles"].each do |role_key|
  openstack_identity_register "Register '#{role_key.to_s}' Role" do
    auth_uri auth_uri
    bootstrap_token bootstrap_token
    role_name role_key

    action :create_role
  end
end


node['openstack']['services'].each_key do |service|
    cu_user = node['openstack']['identity']["#{service}"]['username']
    cu_pass = node['openstack']['identity']["#{service}"]['password']
    cu_tenant = node['openstack']['identity']["#{service}"]['tenant']
    cu_role = node['openstack']['identity']["#{service}"]['role']
    
    if "#{service}" != "identity"   
        openstack_identity_register "Register '#{service}' User" do
            auth_uri auth_uri
            bootstrap_token bootstrap_token
            user_name cu_user
            user_pass cu_pass
            tenant_name cu_tenant
            user_enabled true # Not required as this is the default
            action :create_user
        end
        
        openstack_identity_register "Grant #{cu_role} Role to #{cu_user} User in #{cu_tenant} Tenant" do
            auth_uri auth_uri
            bootstrap_token bootstrap_token
            user_name cu_user
            role_name cu_role
            tenant_name cu_tenant       
            action :grant_role
        end    
    end
    
    cu_service = node['openstack']['services']["#{service}"]['name']
    
    openstack_identity_register "Register #{service} Service" do
        auth_uri auth_uri
        bootstrap_token bootstrap_token
        service_name "#{cu_service}"
        service_type "#{service}"
        service_description "Openstack #{service} Service"        
        action :create_service
    end    
    
    if %Q/#{node['openstack']['services']["#{service}"]['status']}/ == "enable"
        service_endpoint = endpoint "#{service}-api"
        if service == "identity" or service == "compute-ec2" or service == "swift"
            service_endpoint_admin = endpoint "#{service}-admin"
        elsif
            service_endpoint_admin = service_endpoint
        end
        node.set['openstack']["#{service}"]['adminURL'] = service_endpoint_admin.to_s
        node.set['openstack']["#{service}"]['internalURL'] = service_endpoint.to_s
        node.set['openstack']["#{service}"]['publicURL'] = service_endpoint.to_s
        
        openstack_identity_register "Register #{service} Endpoint" do
            auth_uri auth_uri
            bootstrap_token bootstrap_token
            service_type "#{service}"
            endpoint_region node["openstack"]["identity"]["region"]
            endpoint_adminurl node['openstack']["#{service}"]['adminURL']
            endpoint_internalurl node['openstack']["#{service}"]['internalURL']
            endpoint_publicurl node['openstack']["#{service}"]['publicURL']        
            action :create_endpoint
        end
    end
end


node["openstack"]["identity"]["users"].each do |username, user_info|
  openstack_identity_register "Create EC2 credentials for '#{username}' user" do
    auth_uri auth_uri
    bootstrap_token bootstrap_token
    user_name username
    tenant_name user_info["default_tenant"]

    action :create_ec2_credentials
  end
end

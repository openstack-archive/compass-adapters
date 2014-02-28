#
# Cookbook Name:: openstack-common
# Attributes:: default
#
# Copyright 2013, Futurewei, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
# import initial data from databag with customized user data.
#

class ::Chef::Recipe
  include ::Openstack
end

defaultbag = "openstack"
if !Chef::DataBag.list.key?(defaultbag)
    Chef::Application.fatal!("databag '#{defaultbag}' doesn't exist.")
    return
end

myitem = node.attribute?('cluster')? node['cluster']:"env_default"

if !search(defaultbag, "id:#{myitem}")
    Chef::Application.fatal!("databagitem '#{myitem}' doesn't exist.")
    return
end

mydata = data_bag_item(defaultbag, myitem)
# use unsecreted text username and password at chef server.
node.override['openstack']['developer_mode'] = mydata['credential']['text']

# The coordinated release of OpenStack codename
node.override['openstack']['release'] = mydata['release']

# Openstack repo setup
# ubuntu
node.override['openstack']['apt']['components'] = [ "precise-updates/#{node['openstack']['release']}", "main" ]

# redhat
node.override['openstack']['yum']['openstack']['url']="http://repos.fedorapeople.org/repos/openstack/openstack-#{node['openstack']['release']}/epel-#{node['platform_version'].to_i}/"

# Tenant and user
node.override['openstack']['identity']['admin_token'] = mydata['credential']['identity']['token']['admin']
node.override['openstack']['identity']['tenants'] = ["#{ mydata['credential']['identity']['tenants']['admin']}", "#{ mydata['credential']['identity']['tenants']['service']}"]
node.override["openstack"]["identity"]["roles"] = ["#{ mydata['credential']['identity']['roles']['admin']}", "#{ mydata['credential']['identity']['roles']['member']}"]

node.override['openstack']['identity']['admin_tenant_name'] = mydata['credential']['identity']['tenants']['admin']
node.override['openstack']['identity']['admin_user'] = mydata['credential']['identity']['users']['admin']['username']
node.override['openstack']['identity']['admin_password'] = mydata['credential']['identity']['users']['admin']['password']

# services with related usernames and passwords
node['openstack']['services'].each_key do |service|
    node.override['openstack']['services']["#{service}"]['name'] = mydata['services']["#{service}"]['name']
    node.override['openstack']['services']["#{service}"]['status'] = mydata['services']["#{service}"]['status']
    
    if service != "object-store"
        node.set['openstack']['db']["#{service}"]['username'] = mydata['credential']['mysql']["#{service}"]['username']
        node.set['openstack']['db']["#{service}"]['password'] = mydata['credential']['mysql']["#{service}"]['password']
    end

    if "#{service}" != "identity" and "#{service}" != "dashboard"
        node.override['openstack']['identity']["#{service}"]['username'] = mydata['credential']['identity']['users']["#{service}"]['username']
        node.override['openstack']['identity']["#{service}"]['password'] = mydata['credential']['identity']['users']["#{service}"]['password']
        node.override['openstack']['identity']["#{service}"]['role'] = mydata['credential']['identity']['roles']['admin']
        node.set['openstack']['identity']["#{service}"]['tenant'] = mydata['credential']['identity']['users']["#{service}"]['tenant']
    end
end


# network plugins
node.override["openstack"]["network"]["plugins"] = ['openvswitch', 'openvswitch-agent'] 



# ======================== OpenStack Endpoints ================================
# Identity (keystone)
node.override['openstack']['endpoints']['identity-api']['host'] = mydata['endpoints']['identity']['service']['host']
node.override['openstack']['endpoints']['identity-api']['scheme'] = mydata['endpoints']['identity']['service']['scheme']
node.override['openstack']['endpoints']['identity-api']['port'] = "5000"
node.override['openstack']['endpoints']['identity-api']['path'] = "/v2.0"

node.override['openstack']['endpoints']['identity-admin']['host'] = mydata['endpoints']['identity']['admin']['host']
node.override['openstack']['endpoints']['identity-admin']['scheme'] = mydata['endpoints']['identity']['admin']['scheme']
node.override['openstack']['endpoints']['identity-admin']['port'] = "35357"
node.override['openstack']['endpoints']['identity-admin']['path'] = "/v2.0"

# Compute (Nova)
node.override['openstack']['endpoints']['compute-api']['host'] = mydata['endpoints']['compute']['service']['host']
node.override['openstack']['endpoints']['compute-api']['scheme'] = mydata['endpoints']['compute']['service']['scheme']
#node.override['openstack']['endpoints']['compute-api']['port'] = "8774"
#node.override['openstack']['endpoints']['compute-api']['path'] = "/v2/%(tenant_id)s"

# The OpenStack Compute (Nova) EC2 API endpoint
node.override['openstack']['endpoints']['compute-ec2-api']['host'] = mydata['endpoints']['ec2']['service']['host']
node.override['openstack']['endpoints']['compute-ec2-api']['scheme'] = mydata['endpoints']['ec2']['service']['scheme']
#node.override['openstack']['endpoints']['compute-ec2-api']['port'] = "8773"
#node.override['openstack']['endpoints']['compute-ec2-api']['path'] = "/services/Cloud"

# The OpenStack Compute (Nova) EC2 Admin API endpoint
node.override['openstack']['endpoints']['compute-ec2-admin']['host'] = mydata['endpoints']['ec2']['admin']['host']
node.override['openstack']['endpoints']['compute-ec2-admin']['scheme'] = mydata['endpoints']['ec2']['admin']['scheme']
#node.override['openstack']['endpoints']['compute-ec2-admin']['port'] = "8773"
#node.override['openstack']['endpoints']['compute-ec2-admin']['path'] = "/services/Admin"

# The OpenStack Compute (Nova) XVPvnc endpoint
node.override['openstack']['endpoints']['compute-xvpvnc']['host'] = mydata['endpoints']['compute']['xvpvnc']['host']
node.override['openstack']['endpoints']['compute-xvpvnc']['scheme'] = mydata['endpoints']['compute']['xvpvnc']['scheme']
#node.override['openstack']['endpoints']['compute-xvpvnc']['port'] = "6081"
#node.override['openstack']['endpoints']['compute-xvpvnc']['path'] = "/console"

# The OpenStack Compute (Nova) novnc endpoint
node.override['openstack']['endpoints']['compute-novnc']['host'] = mydata['endpoints']['compute']['novnc']['host']
node.override['openstack']['endpoints']['compute-novnc']['scheme'] = mydata['endpoints']['compute']['novnc']['scheme']
#node.override['openstack']['endpoints']['compute-novnc']['port'] = "6080"
#node.override['openstack']['endpoints']['compute-novnc']['path'] = "/vnc_auto.html"


# Network (Quantum)
node.override['openstack']['endpoints']['network-api']['host'] = mydata['endpoints']['network']['service']['host']
node.override['openstack']['endpoints']['network-api']['scheme'] = mydata['endpoints']['network']['service']['scheme']
#node.override['openstack']['endpoints']['network-api']['port'] = "9696"
# quantumclient appends the protocol version to the endpoint URL, so the

# Image (Glance)
node.override['openstack']['endpoints']['image-api']['host'] = mydata['endpoints']['image']['service']['host']
node.override['openstack']['endpoints']['image-api']['scheme'] = mydata['endpoints']['image']['service']['scheme']
#node.override['openstack']['endpoints']['image-api']['port'] = "9292"
#node.override['openstack']['endpoints']['image-api']['path'] = "/v2"

# Image (Glance) Registry
node.override['openstack']['endpoints']['image-registry']['host'] = mydata['endpoints']['image']['registry']['host']
node.override['openstack']['endpoints']['image-registry']['scheme'] = mydata['endpoints']['image']['registry']['scheme']
node.override['openstack']['endpoints']['image-registry']['port'] = "9191"
node.override['openstack']['endpoints']['image-registry']['path'] = "/v2"

# Volume (Cinder)
node.override['openstack']['endpoints']['volume-api']['host'] = mydata['endpoints']['volume']['service']['host']
node.override['openstack']['endpoints']['volume-api']['scheme'] = mydata['endpoints']['volume']['service']['scheme']
#node.override['openstack']['endpoints']['volume-api']['port'] = "8776"
#node.override['openstack']['endpoints']['volume-api']['path'] = "/v1/%(tenant_id)s"

# Metering (Ceilometer)
node.override['openstack']['endpoints']['metering-api']['host'] = mydata['endpoints']['metering']['service']['host']
node.override['openstack']['endpoints']['metering-api']['scheme'] = mydata['endpoints']['metering']['service']['scheme']
#node.override['openstack']['endpoints']['metering-api']['port'] = "8777"
#node.override['openstack']['endpoints']['metering-api']['path'] = "/v1"


# ======================== OpenStack DB Support ================================
# set database attributes
#node.override['openstack']['db']['server_role'] = "os-ops-database"
node.override['openstack']['db']['service_type'] = mydata['db']['service_type']
node.override['openstack']['db']['bind_address'] = mydata['db']["#{node['openstack']['db']['service_type']}"]['bind_address']
node.override['openstack']['db']['port'] = mydata['db']["#{node['openstack']['db']['service_type']}"]['port']

node.override['openstack']['db']['super']['username'] = mydata['credential']["#{node['openstack']['db']['service_type']}"]['super']['username']
node.override['openstack']['db']['super']['password'] = mydata['credential']["#{node['openstack']['db']['service_type']}"]['super']['password']

# Database used by the OpenStack Compute (Nova) service
node.override['openstack']['db']['compute']['db_type'] = node['openstack']['db']['service_type']
node.override['openstack']['db']['compute']['host'] = node['openstack']['db']['bind_address']
node.override['openstack']['db']['compute']['port'] = node['openstack']['db']['port']
#node.override['openstack']['db']['compute']['db_name'] = "nova"

# Database used by the OpenStack Identity (Keystone) service
node.override['openstack']['db']['identity']['db_type'] = node['openstack']['db']['service_type']
node.override['openstack']['db']['identity']['host'] = node['openstack']['db']['bind_address']
node.override['openstack']['db']['identity']['port'] = node['openstack']['db']['port']
#node.override['openstack']['db']['identity']['db_name'] = "keystone"

# Database used by the OpenStack Image (Glance) service
node.override['openstack']['db']['image']['db_type'] = node['openstack']['db']['service_type']
node.override['openstack']['db']['image']['host'] = node['openstack']['db']['bind_address']
node.override['openstack']['db']['image']['port'] = node['openstack']['db']['port']
#node.override['openstack']['db']['image']['db_name'] = "glance"

# Database used by the OpenStack Network (Quantum) service
node.override['openstack']['db']['network']['db_type'] = node['openstack']['db']['service_type']
node.override['openstack']['db']['network']['host'] = node['openstack']['db']['bind_address']
node.override['openstack']['db']['network']['port'] = node['openstack']['db']['port']
#node.override['openstack']['db']['network']['db_name'] = "quantum"

# Database used by the OpenStack Volume (Cinder) service
node.override['openstack']['db']['volume']['db_type'] = node['openstack']['db']['service_type']
node.override['openstack']['db']['volume']['host'] = node['openstack']['db']['bind_address']
node.override['openstack']['db']['volume']['port'] = node['openstack']['db']['port']
#node.override['openstack']['db']['volume']['db_name'] = "cinder"

# Database used by the OpenStack Dashboard (Horizon)
node.override['openstack']['db']['dashboard']['db_type'] = node['openstack']['db']['service_type']
node.override['openstack']['db']['dashboard']['host'] = node['openstack']['db']['bind_address']
node.override['openstack']['db']['dashboard']['port'] = node['openstack']['db']['port']
#node.override['openstack']['db']['dashboard']['db_name'] = "horizon"

# Database used by OpenStack Metering (Ceilometer)
node.override['openstack']['db']['metering']['db_type'] = node['openstack']['db']['service_type']
node.override['openstack']['db']['metering']['host'] = node['openstack']['db']['bind_address']
node.override['openstack']['db']['metering']['port'] = node['openstack']['db']['port']
#node.override['openstack']['db']['metering']['db_name'] = "ceilometer"

# node.override database attributes
#node.override['openstack']['mq']['server_role'] = "os-ops-messaging"
node.override['openstack']['mq']['service_type'] = mydata['mq']['service_type']
node.override['openstack']['mq']['bind_address'] = mydata['mq']["#{node['openstack']['mq']['service_type']}"]['bind_address']
node.override['openstack']['mq']['port'] = mydata['mq']["#{node['openstack']['mq']['service_type']}"]['port']
node.override['openstack']['mq']['user'] = mydata['credential']['mq']["#{node['openstack']['mq']['service_type']}"]['username']
node.override['openstack']['mq']['password'] = mydata['credential']['mq']["#{node['openstack']['mq']['service_type']}"]['password']
#node.override['openstack']['mq']['vhost'] = "/"




# ============================= Network service Configuration =====================
# Gets set in the Network Endpoint when registering with Keystone
node.override["openstack"]["network"]["service_user"] = node['openstack']['identity']['network']['username']
node.override["openstack"]["network"]["service_role"] = node['openstack']['identity']['network']['role']
node.override["openstack"]["network"]["service_name"] = node['openstack']['services']['network']['name']
# node.override["openstack"]["network"]["service_type"] = "network"
# node.override["openstack"]["network"]["description"] = "OpenStack Networking service"

# The rabbit user's password is stored in an encrypted databag
# and accessed with openstack-common cookbook library's
# user_password routine.  You are expected to create
# the user, pass, vhost in a wrapper rabbitmq cookbook.
#node.override["openstack"]["network"]["rabbit_server_chef_role"] = "rabbitmq-server"
node.override["openstack"]["network"]["rabbit"]["username"] = node['openstack']['mq']['user']
#node.override["openstack"]["network"]["rabbit"]["vhost"] = "/"
node.override["openstack"]["network"]["rabbit"]["port"] = node['openstack']['mq']['port']
node.override["openstack"]["network"]["rabbit"]["host"] = node['openstack']['mq']['bind_address']
#node.override["openstack"]["network"]["rabbit"]["ha"] = false

# The database username for the quantum database
node.override["openstack"]["network"]["db"]["username"] = mydata['credential']['mysql']['network']['username']

# Used in the Keystone authtoken middleware configuration
node.override["openstack"]["network"]["service_tenant_name"] = node['openstack']['identity']['network']['tenant']
node.override["openstack"]["network"]["service_user"] = node['openstack']['identity']['network']['username']
node.override["openstack"]["network"]["service_role"] = node['openstack']['identity']['network']['role']

node.override["openstack"]["network"]["api"]["bind_interface"] = mydata['networking']['control']['interface']

node.set['openstack']['networking']['control']['interface'] = mydata['networking']['control']['interface']
node.set['openstack']['networking']['tenant']['interface'] = mydata['networking']['tenant']['interface']
node.set['openstack']['networking']['public']['interface'] = mydata['networking']['public']['interface']
node.set['openstack']['networking']['storage']['interface'] = mydata['networking']['storage']['interface']


# ============================= L3 Agent Configuration =====================

# Indicates that this L3 agent should also handle routers that do not have
# an external network gateway configured.  This option should be True only
# for a single agent in a Quantum deployment, and may be False for all agents
# if all routers must have an external network gateway
#node.override["openstack"]["network"]["l3"]["handle_internal_only_routers"] = "False"

# Name of bridge used for external network traffic. This should be set to
# empty value for the linux bridge
# node.override["openstack"]["network"]["l3"]["external_network_bridge"] = "br-ex"

# Interface to use for external bridge.
node.override["openstack"]["network"]["l3"]["external_network_bridge_interface"] = mydata['networking']['public']['interface']


# ============================= Metadata Agent Configuration ===============

# The location of the Nova Metadata API service to proxy to (nil uses node.override)
node.override["openstack"]["network"]["metadata"]["nova_metadata_ip"] = mydata['endpoints']['compute']['service']['host']
#node.override["openstack"]["network"]["metadata"]["nova_metadata_port"] = 8775

# The name of the secret databag containing the metadata secret
node.override["openstack"]["network"]["metadata"]["secret_name"] = mydata['credential']['metadata']['password']


# ============================= OVS Plugin Configuration ===================

# Type of network to allocate for tenant networks. The node.override value 'local' is
# useful only for single-box testing and provides no connectivity between hosts.
# You MUST either change this to 'vlan' and configure network_vlan_ranges below
# or change this to 'gre' and configure tunnel_id_ranges below in order for tenant
# networks to provide connectivity between hosts. Set to 'none' to disable creation
# of tenant networks.

tenant_network_type = mydata['networking']['plugins']['ovs']['tenant_network_type']
node.override["openstack"]["network"]["openvswitch"]["tenant_network_type"] =tenant_network_type

# Comma-separated list of <physical_network>[:<vlan_min>:<vlan_max>] tuples enumerating
# ranges of VLAN IDs on named physical networks that are available for allocation.
# All physical networks listed are available for flat and VLAN provider network
# creation. Specified ranges of VLAN IDs are available for tenant network
# allocation if tenant_network_type is 'vlan'. If empty, only gre and local
# networks may be created
#
# Example: network_vlan_ranges = physnet1:1000:2999
node.override["openstack"]["network"]["openvswitch"]["network_vlan_ranges"] =mydata['networking']['plugins']['ovs']["#{tenant_network_type}"]['network_vlan_ranges']

# Set to True in the server and the agents to enable support
# for GRE networks. Requires kernel support for OVS patch ports and
# GRE tunneling.
node.override["openstack"]["network"]["openvswitch"]["enable_tunneling"] = mydata['networking']['plugins']['ovs']["#{tenant_network_type}"]['enable_tunneling']

# Comma-separated list of <tun_min>:<tun_max> tuples
# enumerating ranges of GRE tunnel IDs that are available for tenant
# network allocation if tenant_network_type is 'gre'.
#
# Example: tunnel_id_ranges = 1:1000
node.override["openstack"]["network"]["openvswitch"]["tunnel_id_ranges"] = mydata['networking']['plugins']['ovs']["#{tenant_network_type}"]['tunnel_id_ranges']

# Do not change this parameter unless you have a good reason to.
# This is the name of the OVS integration bridge. There is one per hypervisor.
# The integration bridge acts as a virtual "patch bay". All VM VIFs are
# attached to this bridge and then "patched" according to their network
# connectivity
node.override["openstack"]["network"]["openvswitch"]["integration_bridge"] = mydata['networking']['plugins']['ovs']['integration_bridge']

# Only used for the agent if tunnel_id_ranges (above) is not empty for
# the server.  In most cases, the node.override value should be fine
node.override["openstack"]["network"]["openvswitch"]["tunnel_bridge"] = mydata['networking']['plugins']['ovs']["#{tenant_network_type}"]['tunnel_bridge']

# Uncomment this line for the agent if tunnel_id_ranges (above) is not
# empty for the server. Set local_ip to be the local IP address of
# this hypervisor or set the local_ip_interface parameter to use the IP
# address of the specified interface.  If local_ip_interface is set
# it will take precedence.
#local_ip_interface = mydata['networking']['plugins']['ovs']["#{tenant_network_type}"]['local_ip_interface']
local_ip_interface = mydata['networking']['tenant']['interface']
if local_ip_interface != ("nil")
     local_ip= address_for(local_ip_interface)
else
    local_ip="nil"
end

node.override["openstack"]["network"]["openvswitch"]["local_ip"] = local_ip
node.override["openstack"]["network"]["openvswitch"]["local_ip_interface"] = local_ip_interface

# Comma-separated list of <physical_network>:<bridge> tuples
# mapping physical network names to the agent's node-specific OVS
# bridge names to be used for flat and VLAN networks. The length of
# bridge names should be no more than 11. Each bridge must
# exist, and should have a physical network interface configured as a
# port. All physical networks listed in network_vlan_ranges on the
# server should have mappings to appropriate bridges on each agent.
#
# Example: bridge_mappings = physnet1:br-eth1
node.override["openstack"]["network"]["openvswitch"]["bridge_mappings"] = mydata['networking']['plugins']['ovs']["#{tenant_network_type}"]['bridge_mappings']


# #### nova #####
node.override["openstack"]["compute"]["network"]["service_type"] = mydata['networking']['nova']['network_type']


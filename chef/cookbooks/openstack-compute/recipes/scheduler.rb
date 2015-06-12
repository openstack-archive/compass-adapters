# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: scheduler
# Copyright 2013, Craig Tracey <craigtracey@gmail.com>
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

include_recipe 'openstack-compute::nova-common'

platform_options = node['openstack']['compute']['platform']

directory '/var/lock/nova' do
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode  00700

  action :create
end

platform_options['compute_scheduler_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']

    action :upgrade
  end
end

db_user = node['openstack']['db']['compute']['username']
db_pass = get_password 'db', node["openstack"]["compute"]["service_user"]
sql_connection = db_uri('compute', db_user, db_pass)

mq_service_type = node['openstack']['mq']['compute']['service_type']

if mq_service_type == 'rabbitmq'
  node['openstack']['mq']['compute']['rabbit']['ha'] && (rabbit_hosts = rabbit_servers)
  mq_password = get_password('user', \
                  node['openstack']['mq']['user'], \
                  node['openstack']['mq']['password'])
elsif mq_service_type == 'qpid'
  mq_password = get_password('user', \
                  node['openstack']['mq']['compute']['qpid']['username'])
end

if node['openstack']['compute']['consoleauth']['token']['backend'].eql?('memcache')
  memcache_servers = memcached_servers('os-ops-caching').join ','
end

# find the node attribute endpoint settings for the server holding a given role
identity_endpoint = endpoint 'identity-api'
xvpvnc_endpoint = endpoint 'compute-xvpvnc' || {}
xvpvnc_bind = endpoint 'compute-xvpvnc-bind' || {}
novnc_endpoint = endpoint 'compute-novnc' || {}
novnc_bind = endpoint 'compute-novnc-bind' || {}
vnc_bind = endpoint 'compute-vnc-bind' || {}
compute_api_bind = endpoint 'compute-api-bind' || {}
compute_api_endpoint = endpoint 'compute-api' || {}
ec2_api_bind = endpoint 'compute-ec2-api-bind' || {}
ec2_public_endpoint = endpoint 'compute-ec2-api' || {}
network_endpoint = endpoint 'network-api' || {}
image_endpoint = endpoint 'image-api'

Chef::Log.debug("openstack-compute::nova-common:identity_endpoint|#{identity_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:xvpvnc_endpoint|#{xvpvnc_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:novnc_endpoint|#{novnc_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:compute_api_endpoint|#{::URI.decode compute_api_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:ec2_public_endpoint|#{ec2_public_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:network_endpoint|#{network_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:image_endpoint|#{image_endpoint.to_s}")

if node['openstack']['compute']['network']['service_type'] == 'neutron'
  neutron_admin_password = get_password 'service', node["openstack"]["network"]["service_user"]
  neutron_metadata_proxy_shared_secret = get_secret node['openstack']['network']['metadata']['secret_name']
end

if node['openstack']['compute']['libvirt']['images_type'] == 'rbd'
  #rbd_secret_uuid = get_secret node['openstack']['compute']['libvirt']['rbd']['rbd_secret_name']
end

vmware_host_pass = get_secret node['openstack']['compute']['vmware']['secret_name']

if node['platform_family'] == 'suse'
  if node['lsb']['codename'] == 'UVP'
    template '/etc/init.d/openstack-nova-scheduler' do
      source 'openstack-nova-scheduler.service.erb'
      owner "root"
      group "root"
      mode 00755
    end
  end 
end

service 'nova-scheduler' do
  service_name platform_options['compute_scheduler_service']
  supports status: true, restart: true
  subscribes :restart, resources('template[/etc/nova/nova.conf]')

  action [:enable, :start]
end

ruby_block "service nova-scheduler restart if necessary" do
  block do
    Chef::Log.info("service nova-scheduler restart")
  end
  not_if "service #{platform_options['compute_scheduler_service']} status"
  notifies :restart, 'service[nova-scheduler]', :immediately
end

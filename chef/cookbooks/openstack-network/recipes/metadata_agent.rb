# Encoding: utf-8
#
# Cookbook Name:: openstack-network
# Recipe:: metadata_agent
#
# Copyright 2013, AT&T
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

['quantum', 'neutron'].include?(node['openstack']['compute']['network']['service_type']) || return

include_recipe 'openstack-network::common'

platform_options = node['openstack']['network']['platform']

identity_endpoint = endpoint 'identity-api'
service_pass = get_password 'service', node["openstack"]["network"]["service_user"]
metadata_secret = get_secret node['openstack']['network']['metadata']['secret_name']
compute_api_endpoint = endpoint 'compute-api' || {}

platform_options['neutron_metadata_agent_packages'].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options['package_overrides']
  end
end

if node['platform_family'] == 'suse'
  if node['lsb']['codename'] == 'UVP'
    template '/etc/init.d/openstack-neutron-metadata-agent' do
      source 'openstack-neutron-metadata-agent.service.erb'
      owner "root"
      group "root"
      mode 00755
    end
  end
end

template '/etc/neutron/metadata_agent.ini' do
  source 'metadata_agent.ini.erb'
  owner node['openstack']['network']['platform']['user']
  group node['openstack']['network']['platform']['group']
  mode   00644
  variables(
    identity_endpoint: identity_endpoint,
    metadata_secret: metadata_secret,
    nova_metadata_ip: compute_api_endpoint.host,
    service_pass: service_pass
  )
  notifies :restart, 'service[neutron-metadata-agent]', :delayed
  action :create
end

service 'neutron-metadata-agent' do
  service_name platform_options['neutron_metadata_agent_service']
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/neutron/neutron.conf]'
end

ruby_block "service neutron-metadata-agent restart if necessary" do
  block do
    Chef::Log.info("service neutron-metadata-agent restart")
  end
  not_if "service #{platform_options['neutron_metadata_agent_service']} status"
  notifies :restart, 'service[neutron-metadata-agent]', :immediately
end

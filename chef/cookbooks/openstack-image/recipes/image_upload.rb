# encoding: UTF-8
#
# Cookbook Name:: openstack-image
# Recipe:: image_upload
#
# Copyright 2013, IBM Corp.
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

if node['openstack']['image']['syslog']['use']
  include_recipe 'openstack-common::logging'
end

unless node['local_repo'].nil? or node['local_repo'].empty?
  node.override['openstack']['image']['upload_image']['cirros'] = "#{node['local_repo']}/cirros-0.3.2-x86_64-disk.img"
end

platform_options = node['openstack']['image']['platform']
platform_options['image_client_packages'].each do |pkg|
  package pkg do
    action :upgrade
  end
end

if node['platform_family'] == 'suse'
  service 'glance-api restart before image upload' do
    service_name platform_options['image_api_service']
    action :restart
  end
end

identity_endpoint = endpoint 'identity-api'

# For glance client, only identity v2 is supported. See discussion on
# https://bugs.launchpad.net/openstack-chef/+bug/1207504
# So here auth_uri can not be transformed.
auth_uri = identity_endpoint.to_s

service_pass = get_password 'service', 'openstack-image'
service_tenant_name = node['openstack']['image']['service_tenant_name']
service_user = node['openstack']['image']['service_user']

unless node['proxy_url'].nil? or node['proxy_url'].empty?
  node['openstack']['image']['upload_images'].each do |img|
    execute "download_#{node['openstack']['image']['upload_image'][img.to_sym]}" do
      command "wget #{node['openstack']['image']['upload_image'][img.to_sym]}"
      cwd Chef::Config['file_cache_path']
      not_if { ::File.exists?(::File.basename(node['openstack']['image']['upload_image'][img.to_sym])) }
      environment ({ 'http_proxy' =>  node['proxy_url'], 'https_proxy' => node['proxy_url'] })
    end
  end
end

node['openstack']['image']['upload_images'].each do |img|
  openstack_image_image "Image setup for #{img.to_s}" do
    image_url node['openstack']['image']['upload_image'][img.to_sym]
    image_name img
    identity_user service_user
    identity_pass service_pass
    identity_tenant service_tenant_name
    identity_uri auth_uri
    action :upload
  end
end

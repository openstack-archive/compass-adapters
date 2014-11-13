# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: libvirt_rbd
#
# Copyright 2014, x-ion GmbH
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

if node['openstack']['block-storage']['volume']['driver'] == 'cinder.volume.drivers.rbd.RBDDriver'

  include_recipe 'ceph::_common'
  include_recipe 'ceph::mon_install'
  include_recipe 'ceph::conf'
  cluster = 'ceph'

  platform_options = node['openstack']['compute']['platform']

  platform_options['libvirt_ceph_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end

  unless node['local_repo'].nil? or node['local_repo'].empty?
    node.override['ceph']['rhel']['extras']['repository'] = "#{node['local_repo']}/compass_repo"
  end

  save_http_proxy = Chef::Config[:http_proxy]
  unless node['proxy_url'].nil? or node['proxy_url'].empty?
    Chef::Config[:http_proxy] = "#{node['proxy_url']}"
    ENV['http_proxy'] = "#{node['proxy_url']}"
    ENV['HTTP_PROXY'] = "#{node['proxy_url']}"
  end

  execute "rpm -Uvh --force #{node['ceph']['rhel']['extras']['repository']}/qemu-kvm-0.12.1.2-2.415.el6.3ceph.x86_64.rpm #{node['ceph']['rhel']['extras']['repository']}/qemu-img-0.12.1.2-2.415.el6.3ceph.x86_64.rpm" do
    not_if "rpm -qa | grep qemu | grep ceph"
  end

  Chef::Config[:http_proxy] = save_http_proxy
  ENV['http_proxy'] = save_http_proxy
  ENV['HTTP_PROXY'] = save_http_proxy

  secret_uuid = node['openstack']['block-storage']['rbd_secret_uuid']
  rbd_user = node['openstack']['compute']['libvirt']['rbd']['rbd_user']

  if mon_nodes.empty?
    rbd_key = ""
  elsif !mon_master['ceph'].has_key?('cinder-secret')
    rbd_key = ""
  else
    rbd_key = mon_master['ceph']['cinder-secret']
  end

  template "/etc/ceph/ceph.client.#{rbd_user}.keyring" do
    source 'ceph.client.keyring.erb'
    cookbook 'openstack-common'
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']
    mode '0644'
    variables(
        name: rbd_user,
        key: rbd_key
    )
  end

  require 'securerandom'
  filename = SecureRandom.hex

  template "/tmp/#{filename}.xml" do
    source 'secret.xml.erb'
    user 'root'
    group 'root'
    mode '700'
    variables(
        uuid: secret_uuid,
        client_name: node['openstack']['compute']['libvirt']['rbd']['rbd_user']
    )
    not_if "virsh secret-list | grep #{secret_uuid}"
  end

  execute "virsh secret-define --file /tmp/#{filename}.xml" do
    not_if "virsh secret-list | grep #{secret_uuid}"
  end

  # this will update the key if necessary
  execute 'set libvirt secret' do
    command "virsh secret-set-value --secret #{secret_uuid} --base64 #{rbd_key}"
    notifies :restart, 'service[nova-compute-ceph]', :immediately
  end

  file "/tmp/#{filename}.xml" do
    action :delete
  end

  service 'nova-compute-ceph' do
    service_name platform_options['compute_compute_service']
    supports status: true, restart: true
    subscribes :restart, resources('template[/etc/nova/nova.conf]')

    action :restart
  end
end

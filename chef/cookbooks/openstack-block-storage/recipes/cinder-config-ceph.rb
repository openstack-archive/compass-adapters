# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage
# Recipe:: volume
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2012-2013, AT&T Services, Inc.
# Copyright 2013, Opscode, Inc.
# Copyright 2013, SUSE Linux Gmbh.
# Copyright 2013, IBM, Corp.
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

if node['openstack']['block-storage']['volume']['driver']  == 'cinder.volume.drivers.rbd.RBDDriver'

  include_recipe 'ceph::_common'
  include_recipe 'ceph::mon_install'
  include_recipe 'ceph::conf'
  cluster = 'ceph'

  platform_options = node['openstack']['block-storage']['platform']

  platform_options['cinder_volume_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end

  rbd_user = node['openstack']['block-storage']['rbd_user']

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

  include_recipe 'openstack-block-storage::cinder-common'

  service 'cinder-volume-ceph' do
    service_name platform_options['cinder_volume_service']
    supports status: true, restart: true
    action :restart
    subscribes :restart, 'template[/etc/cinder/cinder.conf]'
  end
end

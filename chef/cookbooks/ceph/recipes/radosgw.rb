#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: radosgw
#
# Copyright 2011, DreamHost Web Hosting
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

node.default['ceph']['is_radosgw'] = true

include_recipe 'ceph::_common'
include_recipe 'ceph::radosgw_install'
include_recipe 'ceph::conf'

directory '/var/run/ceph' do
  owner 'apache'
  group 'apache'
  mode 00755
  recursive true
  action :create
end

if !::File.exist?("/var/lib/ceph/radosgw/ceph-radosgw.#{node['hostname']}/done")
  if node['ceph']['radosgw']['webserver_companion']
    include_recipe "ceph::radosgw_#{node['ceph']['radosgw']['webserver_companion']}"
  end

  ceph_client 'radosgw' do
    caps('mon' => 'allow rw', 'osd' => 'allow rwx')
  end

  d_owner = d_group = 'apache'
  %W(
     /etc/ceph/ceph.client.radosgw.#{node['hostname']}.keyring
     /var/log/ceph/radosgw.log
  ).each do |f|
    file f do
      owner d_owner
      group d_group
      action :create
    end
  end

  directory "/var/lib/ceph/radosgw/ceph-radosgw.#{node['hostname']}" do
    recursive true
  end

  file "/var/lib/ceph/radosgw/ceph-radosgw.#{node['hostname']}/done" do
    action :create
  end

  service 'radosgw' do
    case node['ceph']['radosgw']['init_style']
      when 'upstart'
        service_name 'radosgw-all-starter'
        provider Chef::Provider::Service::Upstart
      else
        if node['platform'] == 'debian'
          service_name 'radosgw'
        else
          service_name 'ceph-radosgw'
        end
    end
    supports :restart => true
    action [:enable, :start]
  end

  execute 'set selinux permissive' do
    command "setenforce 0"
    not_if {selinux_disabled?}
  end

else
  Log.info('Rados Gateway already deployed')
end

service 'radosgw' do
  case node['ceph']['radosgw']['init_style']
    when 'upstart'
      service_name 'radosgw-all-starter'
      provider Chef::Provider::Service::Upstart
    else
      if node['platform'] == 'debian'
        service_name 'radosgw'
      else
        service_name 'ceph-radosgw'
      end
  end
  supports :restart => true
  action [:enable, :start]
  subscribes :restart, resources('template[/etc/ceph/ceph.conf]')
end

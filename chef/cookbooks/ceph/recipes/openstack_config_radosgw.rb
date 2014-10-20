#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: radosgw
#
# Copyright 2011, Liucheng
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
node.default['ceph']['is_keystone_integration'] = false

if node['ceph']['is_keystone_integration']
  keystone_master = node_election('os-identity', 'keystone_keygen', node['ceph']['keystone environment'])
  puts "****************keystone_master:#{keystone_master}"
  if keystone_master['openstack']['endpoints']['identity-bind']['host'].nil?
    Chef::Log.debug \
            "Chef-client exit for keystone endpoint bind host on #{keystone_master.name})"
    exit 1
  end
  node.default['ceph']['config']['keystone']['rgw keystone url'] = "#{keystone_master['openstack']['endpoints']['identity-bind']['host']}:35357"

  template '/etc/ceph/ceph.conf' do
    source 'ceph.conf.erb'
    variables lazy {
      {
          :mon_addresses => mon_addresses,
          :is_rgw => node['ceph']['is_radosgw'],
          :is_keystone_integration => node['ceph']['is_keystone_integration']
      }
    }
    mode '0644'
  end

  %w{certfile ca_certs}.each do |name|
    if !keystone_master['openstack']['identity']['signing'].attribute?("#{name}_data")
      Chef::Log.debug \
            "Chef-client exit for PKI files from node #{keystone_master.name})"
      exit 1
    end
    file node['ceph']['radosgw']['signing']["#{name}"] do
      content keystone_master['openstack']['identity']['signing']["#{name}_data"]
      owner   'root'
      group   'root'
      mode    00640
    end
  end

  directory node['ceph']['config']['keystone']['nss db path'] do
    owner 'apache'
    group 'apache'
    mode 00755
    recursive true
    action :create
  end

  if !::File.exist?("#{node['ceph']['config']['keystone']['nss db path']}/done")
    execute 'config ca.pem' do
      command "openssl x509 -in #{node['ceph']['radosgw']['signing']['ca_certs']} -pubkey | certutil -d /var/ceph/nss -A -n ca -t \"TCu,Cu,Tuw\""
    end

    execute 'config signing_cert.pem' do
      command "openssl x509 -in #{node['ceph']['radosgw']['signing']['certfile']} -pubkey | certutil -A -d /var/ceph/nss -n signing_cert -t \"P,P,P\""
    end

    execute 'change owner of nss' do
      command "chown apache:apache -R #{node['ceph']['config']['keystone']['nss db path']}"
    end

    file "#{node['ceph']['config']['keystone']['nss db path']}/done" do
      action :create
    end

  end

  service 'ceph-radosgw' do
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
end

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

include_recipe 'openstack-block-storage::cinder-common'

package 'parted' do
  action :install
end

directory "#{node['openstack']['block-storage']['volume']['state_path']}" do
  owner node['openstack']['block-storage']['user']
  group node['openstack']['block-storage']['group']
  mode  0755
end

directory "#{node['openstack']['block-storage']['volume']['volumes_dir']}" do
  owner node['openstack']['block-storage']['user']
  group node['openstack']['block-storage']['group']
  mode  0755
end

platform_options = node['openstack']['block-storage']['platform']

platform_options['cinder_volume_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

db_type = node['openstack']['db']['block-storage']['service_type']
platform_options["#{db_type}_python_packages"].each do |pkg|
  package pkg do
    action :upgrade
  end
end

platform_options['cinder_iscsitarget_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

case node['openstack']['block-storage']['volume']['driver']
when 'cinder.volume.drivers.netapp.iscsi.NetAppISCSIDriver'
  node.override['openstack']['block-storage']['netapp']['dfm_password'] = get_password 'service', 'netapp'

when 'cinder.volume.drivers.rbd.RBDDriver'
  # this is used in the cinder.conf template
  # node.override['openstack']['block-storage']['rbd_secret_uuid'] = get_secret node['openstack']['block-storage']['rbd_secret_name']
  #
  # rbd_user = node['openstack']['block-storage']['rbd_user']
  # rbd_key = get_password 'service', node['openstack']['block-storage']['rbd_key_name']
  #
  # include_recipe 'openstack-common::ceph_client'
  #
  # platform_options['cinder_ceph_packages'].each do |pkg|
  #   package pkg do
  #     options platform_options['package_overrides']
  #     action :upgrade
  #   end
  # end
  #
  # template "/etc/ceph/ceph.client.#{rbd_user}.keyring" do
  #   source 'ceph.client.keyring.erb'
  #   cookbook 'openstack-common'
  #   owner node['openstack']['block-storage']['user']
  #   group node['openstack']['block-storage']['group']
  #   mode '0600'
  #   variables(
  #     name: rbd_user,
  #     key: rbd_key
  #   )
  # end

when 'cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver'
  node.override['openstack']['block-storage']['netapp']['netapp_server_password'] = get_password 'service', 'netapp-filer'

  directory node['openstack']['block-storage']['nfs']['mount_point_base'] do
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']
    action :create
  end

  template node['openstack']['block-storage']['nfs']['shares_config'] do
    source 'shares.conf.erb'
    mode '0600'
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']
    variables(
      host: node['openstack']['block-storage']['netapp']['netapp_server_hostname'],
      export: node['openstack']['block-storage']['netapp']['export']
    )
    notifies :restart, 'service[cinder-volume]', :delayed
  end

  platform_options['cinder_nfs_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end

when 'cinder.volume.drivers.ibm.storwize_svc.StorwizeSVCDriver'
  file node['openstack']['block-storage']['san']['san_private_key'] do
    mode '0400'
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']
  end

when 'cinder.volume.drivers.gpfs.GPFSDriver'
  directory node['openstack']['block-storage']['gpfs']['gpfs_mount_point_base'] do
    mode '0755'
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']
    recursive true
  end

when 'cinder.volume.drivers.ibm.ibmnas.IBMNAS_NFSDriver'
  directory node['openstack']['block-storage']['ibmnas']['mount_point_base'] do
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']
    mode '0755'
    recursive true
    action :create
  end

  platform_options['cinder_nfs_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end

  template node['openstack']['block-storage']['ibmnas']['shares_config'] do
    source 'nfs_shares.conf.erb'
    mode '0600'
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']
    variables(
      host: node['openstack']['block-storage']['ibmnas']['nas_access_ip'],
      export: node['openstack']['block-storage']['ibmnas']['export']
    )
    notifies :restart, 'service[cinder-volume]', :delayed
  end

when 'cinder.volume.drivers.lvm.LVMISCSIDriver'
#  if node['openstack']['block-storage']['volume']['create_volume_group']
#    volume_size = node['openstack']['block-storage']['volume']['volume_group_size']
#    seek_count = volume_size.to_i * 1024
    # default volume group is 40G
#    seek_count = 40 * 1024 if seek_count == 0
#    vg_name = node['openstack']['block-storage']['volume']['volume_group']
#    vg_file = "#{node['openstack']['block-storage']['volume']['state_path']}/#{vg_name}.img"

    # create volume group
#    execute 'Create Cinder volume group' do
#      command "dd if=/dev/zero of=#{vg_file} bs=1M seek=#{seek_count} count=0; vgcreate #{vg_name} $(losetup --show -f #{vg_file})"
#      action :run
#      not_if "vgs #{vg_name}"
#    end

#    template '/etc/init.d/cinder-group-active' do
#      source 'cinder-group-active.erb'
#      mode '755'
#      variables(
#        volume_name: vg_name,
#        volume_file: vg_file
#      )
#      notifies :start, 'service[cinder-group-active]', :immediately
#    end

#    service 'cinder-group-active' do
#      service_name 'cinder-group-active'

#      action [:enable, :start]
#    end

    package 'bc' do
      action :upgrade
    end

    openstack_block_storage_volume node['openstack']['block-storage']['volume']['disk'] do
      action :create_disk_partition
    end

    openstack_block_storage_volume node['openstack']['block-storage']['volume']['disk'] do
      action :create_file_partition
    end

    openstack_block_storage_volume node['openstack']['block-storage']['volume']['disk'] do
      action :mk_cinder_vol
    end

#    if node['openstack']['block-storage']['volume']['disk'].eql?('loopfile')
#      template '/etc/init.d/cinder-group-active' do
#        source 'cinder-group-active.erb'
#        mode '755'
#        variables(
#          volume_name: vg_name,
#          volume_file: vg_file
#        )
#        notifies :start, 'service[cinder-group-active]', :immediately
#      end

#      service 'cinder-group-active' do
#        service_name 'cinder-group-active'
#        action [:enable, :start]
#      end
#    end

when 'cinder.volume.drivers.emc.emc_smis_iscsi.EMCSMISISCSIDriver'
  platform_options['cinder_emc_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end

  ecom_password = get_password('user', node['openstack']['block-storage']['emc']['EcomUserName'])

  template node['openstack']['block-storage']['emc']['cinder_emc_config_file'] do
    source 'cinder_emc_config.xml.erb'
    variables(
      ecom_password: ecom_password
    )
    mode 00644
    notifies :stop, 'service[iscsitarget]', :delayed
    notifies :start, 'service[iscsitarget]', :delayed
  end
end

if node['platform_family'] == 'suse'
  if node['lsb']['codename'] == 'UVP'
    db_user = node['openstack']['db']['block-storage']['username']
    db_pass = get_password 'db', node["openstack"]["block-storage"]["service_user"]
    sql_connection = db_uri('block-storage', db_user, db_pass)

    mq_service_type = node['openstack']['mq']['block-storage']['service_type']

    if mq_service_type == 'rabbitmq'
      if node['openstack']['mq']['block-storage']['rabbit']['ha']
        rabbit_hosts = rabbit_servers
      end
      #mq_password = get_password 'user', node['openstack']['mq']['block-storage']['rabbit']['userid']
      mq_password = get_password('user', \
                      node['openstack']['mq']['user'], \
                      node['openstack']['mq']['password'])
    elsif mq_service_type == 'qpid'
      #mq_password = get_password 'user', node['openstack']['mq']['block-storage']['qpid']['username']
      mq_password = get_password('user', \
                      node['openstack']['mq']['user'], \
                      node['openstack']['mq']['password'])
    end

    case node['openstack']['block-storage']['volume']['driver']
    when 'cinder.volume.drivers.solidfire.SolidFire'
      solidfire_pass = get_password 'user', node['openstack']['block-storage']['solidfire']['san_login']
    when 'cinder.volume.drivers.ibm.ibmnas.IBMNAS_NFSDriver'
      ibmnas_pass = get_password 'user', node['openstack']['block-storage']['ibmnas']['nas_login']
    when 'cinder.volume.drivers.vmware.vmdk.VMwareVcVmdkDriver'
      vmware_host_pass = get_secret node['openstack']['block-storage']['vmware']['secret_name']
    end

    glance_api_endpoint = endpoint 'image-api'
    cinder_api_bind = endpoint 'block-storage-api-bind'

    template '/etc/cinder/cinder-volume.conf' do
      source 'cinder-volume.conf.erb'
      owner node['openstack']['block-storage']['user']
      group node['openstack']['block-storage']['group']
      mode   00644
      variables(
        sql_connection: sql_connection,
        mq_service_type: mq_service_type,
        mq_password: mq_password,
        rabbit_hosts: rabbit_hosts,
        glance_host: glance_api_endpoint.host,
        glance_port: glance_api_endpoint.port,
        ibmnas_pass: ibmnas_pass,
        solidfire_pass: solidfire_pass,
        volume_api_bind_address: cinder_api_bind.host,
        volume_api_bind_port: cinder_api_bind.port,
        vmware_host_pass: vmware_host_pass
      )

      notifies :restart, 'service[cinder-volume]', :delayed
    end

    template '/etc/init.d/openstack-cinder-volume' do
      source 'openstack-cinder-volume.service.erb'
      owner "root"
      group "root"
      mode 00755
    end
  end 
end

directory '/etc/tgt' do
  owner node['openstack']['block-storage']['user']
  group node['openstack']['block-storage']['group']
  mode  0755
end

template '/etc/tgt/targets.conf' do
  source 'targets.conf.erb'
  owner node['openstack']['block-storage']['user']
  group node['openstack']['block-storage']['group']
  mode   00644
  notifies :stop, 'service[iscsitarget]', :delayed
  notifies :start, 'service[iscsitarget]', :delayed
end

service 'cinder-volume' do
  service_name platform_options['cinder_volume_service']
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/cinder/cinder.conf]'
end

ruby_block "service cinder-volume restart if necessary" do
  block do
    Chef::Log.info("service cinder-volume restart")
  end
  not_if "service #{platform_options['cinder_volume_service']} status"
  notifies :restart, 'service[cinder-volume]', :immediately
end

if node['platform_family'] == 'suse'
  if node['lsb']['codename'] == 'UVP'
    service 'open-iscsi' do
      supports status: true, restart: true
      action [:enable, :start]
    end

    ruby_block "service open-iscsi restart if necessary" do
      block do
        Chef::Log.info("service  open-iscsi restart")
      end
      not_if "service open-iscsi status"
      notifies :restart, 'service[open-iscsi]', :immediately
    end
  end
end

service 'iscsitarget' do
  service_name platform_options['cinder_iscsitarget_service']
  supports status: true, restart: true
  action [:enable, :start]
end

ruby_block "service iscsitarget restart if necessary" do
  block do
    Chef::Log.info("service iscsitarget restart")
  end
  not_if "service #{platform_options['cinder_iscsitarget_service']} status"
  notifies :stop, 'service[iscsitarget]', :immediately
  notifies :start, 'service[iscsitarget]', :immediately
end

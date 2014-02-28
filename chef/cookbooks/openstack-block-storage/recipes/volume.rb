#
# Cookbook Name:: openstack-block-storage
# Recipe:: volume
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2012-2013, AT&T Services, Inc.
# Copyright 2013, Opscode, Inc.
# Copyright 2013, SUSE Linux Gmbh.
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

class ::Chef::Recipe
  include ::Openstack
end

include_recipe "openstack-block-storage::cinder-common"

platform_options = node["openstack"]["block-storage"]["platform"]

package "parted" do
  action :upgrade
end

platform_options["cinder_volume_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]

    action :upgrade
  end
end

db_type = node['openstack']['db']['volume']['db_type']
platform_options["#{db_type}_python_packages"].each do |pkg|
  package pkg do
    action :upgrade
  end
end

platform_options["cinder_iscsitarget_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]

    action :upgrade
  end
end

directory "/var/lock/cinder" do
  owner node["openstack"]["block-storage"]["user"]
  group node["openstack"]["block-storage"]["group"]
  mode 00700
end

case node["openstack"]["block-storage"]["volume"]["driver"]
  when "cinder.volume.drivers.netapp.iscsi.NetAppISCSIDriver"
   node.override["openstack"]["block-storage"]["netapp"]["dfm_password"] = service_password "netapp"

  when "cinder.volume.drivers.RBDDriver"
   node.override["openstack"]["block-storage"]["rbd_secret_uuid"] = service_password "rbd"

  when "cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver"
    node.override["openstack"]["block-storage"]["netapp"]["netapp_server_password"] = service_password "netapp-filer"

    directory node["openstack"]["block-storage"]["nfs"]["mount_point_base"] do
      owner node["openstack"]["block-storage"]["user"]
      group node["openstack"]["block-storage"]["group"]
      action :create
    end

    template node["openstack"]["block-storage"]["nfs"]["shares_config"] do
      source "shares.conf.erb"
      mode "0600"
      owner node["openstack"]["block-storage"]["user"]
      group node["openstack"]["block-storage"]["group"]
      variables(
        "host" => node["openstack"]["block-storage"]["netapp"]["netapp_server_hostname"],
        "export" => node["openstack"]["block-storage"]["netapp"]["export"]
      )
      notifies :restart, "service[cinder-volume]"
    end

    platform_options["cinder_nfs_packages"].each do |pkg|
      package pkg do
        options platform_options["package_overrides"]

        action :upgrade
      end
    end
   
  when "cinder.volume.drivers.lvm.LVMISCSIDriver"
    package "bc" do
      action :install
    end

    openstack_block_storage_volume node["openstack"]["volume"]["disk"] do
      action :create_partition
    end

    openstack_block_storage_volume node["openstack"]["volume"]["disk"] do
      action :mk_cinder_vol
    end

#    template "/tmp/cinder_volumes.sh" do
#      source "cinder_volumes.sh.erb"
#      owner "root"
#      group "root"
#      mode  00755
#      variables( 
#        :volumesize => node["openstack"]["volume"]["size"]
#      )
#      notifies :run, "execute[create_cinder_volumes]", :immediately
#      only_if { node["openstack"]["volume"]["mode"] == "loopfile" }
#    end

#    execute "create_cinder_volumes" do
#      command "sh /tmp/cinder_volumes.sh"
#      action :run
#      only_if { node["openstack"]["volume"]["mode"] == "loopfile" }
#    end
end

service "cinder-volume" do
  service_name platform_options["cinder_volume_service"]
  supports :status => true, :restart => true

  action [ :enable, :restart ]
  subscribes :restart, "template[/etc/cinder/cinder.conf]"
end

service "iscsitarget" do
  service_name platform_options["cinder_iscsitarget_service"]
  supports :status => true, :restart => true

  action :enable
end

template "/etc/tgt/targets.conf" do
  source "targets.conf.erb"
  mode   00600

  notifies :restart, "service[iscsitarget]", :immediately
end

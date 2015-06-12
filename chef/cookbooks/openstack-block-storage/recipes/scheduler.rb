# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage
# Recipe:: scheduler
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

include_recipe 'openstack-block-storage::cinder-common'

platform_options = node['openstack']['block-storage']['platform']

platform_options['cinder_scheduler_packages'].each do |pkg|
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

    template '/etc/cinder/cinder-scheduler.conf' do
      source 'cinder-scheduler.conf.erb'
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

      notifies :restart, 'service[cinder-scheduler]', :delayed
    end

    template '/etc/init.d/openstack-cinder-scheduler' do
      source 'openstack-cinder-scheduler.service.erb'
      owner "root"
      group "root"
      mode 00755
    end
  end 
end

service 'cinder-scheduler' do
  service_name platform_options['cinder_scheduler_service']
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/cinder/cinder.conf]'
end

ruby_block "service cinder-scheduler restart if necessary" do
  block do
    Chef::Log.info("service cinder-scheduler restart")
  end
  not_if "service #{platform_options['cinder_scheduler_service']} status"
  notifies :restart, 'service[cinder-scheduler]', :immediately
end

audit_bin_dir = platform_family?('debian') ? '/usr/bin' : '/usr/local/bin'
audit_log = node['openstack']['block-storage']['cron']['audit_logfile']

if node['openstack']['telemetry']
  scheduler_role = node['openstack']['block-storage']['scheduler_role']
  results = search(:node, "roles:#{scheduler_role}")
  cron_node = results.map { |a| a.name }.sort[0]
  Chef::Log.debug("Volume audit cron node: #{cron_node}")

  cron 'cinder-volume-usage-audit' do
    day node['openstack']['block-storage']['cron']['day'] || '*'
    hour node['openstack']['block-storage']['cron']['hour'] || '*'
    minute node['openstack']['block-storage']['cron']['minute']
    month node['openstack']['block-storage']['cron']['month'] || '*'
    weekday node['openstack']['block-storage']['cron']['weekday'] || '*'
    command "#{audit_bin_dir}/cinder-volume-usage-audit > #{audit_log} 2>&1"
    action cron_node == node.name ? :create : :delete
    user node['openstack']['block-storage']['user']
  end
end

# attention:
# this recipe should run after the openstack and ceph are working correctly!
#

if node['openstack']['image']['api']['default_store'] == 'rbd'

  include_recipe 'ceph::_common'
  include_recipe 'ceph::mon_install'
  include_recipe 'ceph::conf'
  platform_options = node['openstack']['image']['platform']
  cluster = 'ceph'

  class ::Chef::Recipe # rubocop:disable Documentation
    include ::Openstack
  end

  rbd_user = node['openstack']['image']['api']['rbd']['rbd_store_user']

  if mon_nodes.empty?
    rbd_key = ""
  elsif !mon_master['ceph'].has_key?('glance-secret')
    rbd_key = ""
  else
    rbd_key = mon_master['ceph']['glance-secret']
  end

  template "/etc/ceph/ceph.client.#{rbd_user}.keyring" do
    source 'ceph.client.keyring.erb'
    cookbook 'openstack-common'
    owner node['openstack']['image']['user']
    group node['openstack']['image']['group']
    mode 00600
    variables(
        name: rbd_user,
        key: rbd_key
    )
  end

  service 'glance-api-ceph' do
    service_name platform_options['image_api_service']
    supports status: true, restart: true
    action :enable
    subscribes :restart, resources('template[/etc/ceph/ceph.conf]')
  end
end

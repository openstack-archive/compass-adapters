# attention:
# this recipe should run after the openstack and ceph are running correctly!
#

cluster = 'ceph'

if node['ceph']['openstack_pools'].nil?
  node.normal['ceph']['openstack_pools'] = [{'pool_name'=>'images'},{'pool_name'=>'volumes'},{'pool_name'=>'vms'}]
end

#create pools for openstack volumes and images
if node['ceph']['openstack_pools']
  pools = node['ceph']['openstack_pools']

  pools = Hash[(0...pools.size).zip pools] unless pools.kind_of? Hash

  pools.each do |index, ceph_pools|
    unless ceph_pools['status'].nil?
      Chef::Log.info("osd pools: ceph_pools #{ceph_pools['pool_name']} has already been create.")
      next
    end

    execute "create #{ceph_pools['pool_name']} pool" do
      command "ceph osd pool create #{ceph_pools['pool_name']} #{node['ceph']['config']['global']['osd pool default pg num']}"
      notifies :create, "ruby_block[save osd pools status #{index}]", :immediately
    end

    ruby_block "save osd pools status #{index}" do
      block do
        node.normal['ceph']['openstack_pools'][index]['status'] = 'created'
        node.save
      end
      action :nothing
    end
  end
end

#generate the openstack cinder secret
if node['ceph']['cinder-secret'].nil?
  keyring1 = "client.cinder"
  execute 'generate cinder-secret as keyring' do
    command "ceph auth get-or-create #{keyring1} mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'"
    notifies :create, 'ruby_block[save cinder-secret]', :immediately
  end

  ruby_block 'save cinder-secret' do
    block do
      fetch1 = Mixlib::ShellOut.new("ceph auth print_key '#{keyring1}'")
      fetch1.run_command
      key1 = fetch1.stdout
      node.set['ceph']['cinder-secret'] = key1
      node.save
    end
    action :nothing
  end
end

#generate the openstack glance secret
if node['ceph']['glance-secret'].nil?
  keyring2 = "client.glance"
  execute 'generate cinder-secret as keyring' do
    command "ceph auth get-or-create #{keyring2} mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'"
    notifies :create, 'ruby_block[save glance-secret]', :immediately
  end

  ruby_block 'save glance-secret' do
    block do
      fetch2 = Mixlib::ShellOut.new("ceph auth print_key '#{keyring2}'")
      fetch2.run_command
      key2 = fetch2.stdout
      node.set['ceph']['glance-secret'] = key2
      node.save
    end
    action :nothing
  end
end
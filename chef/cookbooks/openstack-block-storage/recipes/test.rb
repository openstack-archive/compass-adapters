#include_recipe "openstack-block-storage::cinder-common"
#include_recipe "parted::default"

node.set['create_partition'] = false
node.set['partitions'] = nil
openstack_block_storage_volume "/dev/sdb" do
  action :create_partition
end

openstack_block_storage_volume "/dev/sdc" do
  action :create_partition
end

openstack_block_storage_volume "/dev/sdb" do
  action :mk_cinder_vol
end

openstack_block_storage_volume "/dev/sdc" do
  action :mk_cinder_vol
end

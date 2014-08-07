# encoding: UTF-8
require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start! { add_filter 'openstack-ops-messaging' }

LOG_LEVEL = :fatal
REDHAT_OPTS = {
  platform: 'redhat',
  version: '6.5',
  log_level: LOG_LEVEL
}
UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '12.04',
  log_level: LOG_LEVEL
}

shared_context 'ops_messaging_stubs' do
  before do
    Chef::Recipe.any_instance.stub(:address_for)
      .with('lo')
      .and_return '127.0.0.1'
    Chef::Recipe.any_instance.stub(:address_for)
      .with('eth0')
      .and_return '33.44.55.66'
    Chef::Recipe.any_instance.stub(:search)
      .with(:node, 'roles:os-ops-messaging AND chef_environment:_default')
      .and_return [
      { 'hostname' => 'host2' },
      { 'hostname' => 'host1' }
    ]
    Chef::Recipe.any_instance.stub(:get_password)
      .with('user', anything)
      .and_return 'rabbit-pass'
    Chef::Recipe.any_instance.stub(:get_password)
      .with('service', 'rabbit_cookie')
      .and_return 'erlang-cookie'
  end
end

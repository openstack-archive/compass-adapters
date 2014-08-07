# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-ops-messaging::server' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'ops_messaging_stubs'

    it 'uses proper messaging server recipe' do
      expect(chef_run).to include_recipe 'openstack-ops-messaging::rabbitmq-server'
    end
  end
end

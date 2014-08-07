# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-ops-database::client' do
  describe 'ubuntu' do
    include_context 'database-stubs'
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    it 'uses mysql database client recipe by default' do
      expect(chef_run).to include_recipe 'openstack-ops-database::mysql-client'
    end

    it 'uses postgresql database client recipe when configured' do
      node.set['openstack']['db']['service_type'] = 'postgresql'
      node.set['postgresql']['password']['postgres'] = 'secret'

      expect(chef_run).to include_recipe 'openstack-ops-database::postgresql-client'
    end
  end
end

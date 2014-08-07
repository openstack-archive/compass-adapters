# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-ops-database::postgresql-server' do
  describe 'ubuntu' do
    include_context 'database-stubs'

    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      # The postgresql cookbook will raise an 'uninitialized constant
      # Chef::Application' error without this attribute when running
      # the tests
      node.set_unless['postgresql']['password']['postgres'] = String.new

      runner.converge(described_recipe)
    end

    it 'includes postgresql recipes' do
      expect(chef_run).to include_recipe(
        'openstack-ops-database::postgresql-client')
      expect(chef_run).to include_recipe('postgresql::server')
    end
  end
end

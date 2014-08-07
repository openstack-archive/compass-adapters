# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-ops-database::mysql-server' do
  describe 'redhat' do
    include_context 'database-stubs'
    let(:runner) { ChefSpec::Runner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      node.set_unless['mysql'] = {
        'server_debian_password' => 'server-debian-password',
        'server_root_password' => 'server-root-password',
        'server_repl_password' => 'server-repl-password'
      }
      runner.converge(described_recipe)
    end

    it 'modifies my.cnf template to notify mysql restart' do
      file = chef_run.template('final-my.cnf')
      expect(file).to notify('service[mysql]').to(:restart)
    end
  end
end

# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-ops-database::mysql-server' do
  describe 'ubuntu' do
    include_context 'database-stubs'
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      node.set_unless['mysql'] = {
          'server_debian_password' => 'server-debian-password',
          'server_root_password' => 'server-root-password',
          'server_repl_password' => 'server-repl-password'
      }
      runner.converge(described_recipe)
    end

    it 'overrides default mysql attributes' do
      expect(chef_run.node['mysql']['bind_address']).to eql '127.0.0.1'
      expect(chef_run.node['mysql']['tunable']['innodb_thread_concurrency']).to eql '0'
      expect(chef_run.node['mysql']['tunable']['innodb_commit_concurrency']).to eql '0'
      expect(chef_run.node['mysql']['tunable']['innodb_read_io_threads']).to eql '4'
      expect(chef_run.node['mysql']['tunable']['innodb_flush_log_at_trx_commit']).to eql '2'
      expect(chef_run.node['mysql']['tunable']['skip-name-resolve']).to eql true
    end

    it 'includes mysql recipes' do
      expect(chef_run).to include_recipe 'openstack-ops-database::mysql-client'
      expect(chef_run).to include_recipe 'mysql::server'
    end

    it 'modifies my.cnf template to notify mysql restart' do
      file = chef_run.template '/etc/mysql/my.cnf'
      expect(file).to notify('service[mysql]').to(:restart)
    end

    describe 'lwrps' do
      connection = {
        host: 'localhost',
        username: 'root',
        password: 'server-root-password'
      }

      it 'removes insecure default localhost mysql users' do
        resource = chef_run.find_resource(
          'mysql_database',
          'drop empty localhost user'
        ).to_hash

        expect(resource).to include(
          sql: "DELETE FROM mysql.user WHERE User = '' OR Password = ''",
          connection: connection,
          action: [:query]
        )
      end

      it 'drops the test database' do
        resource = chef_run.find_resource(
          'mysql_database',
          'test'
        ).to_hash

        expect(resource).to include(
          connection: connection,
          action: [:drop]
        )
      end

      it 'flushes privileges' do
        resource = chef_run.find_resource(
          'mysql_database',
          'FLUSH PRIVILEGES'
        ).to_hash

        expect(resource).to include(
          connection: connection,
          sql: 'FLUSH PRIVILEGES',
          action: [:query]
        )
      end
    end
  end
end

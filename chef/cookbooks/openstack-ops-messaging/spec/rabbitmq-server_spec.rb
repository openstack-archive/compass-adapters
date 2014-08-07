# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-ops-messaging::rabbitmq-server' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'ops_messaging_stubs'

    it 'overrides default rabbit attributes' do
      expect(chef_run.node['openstack']['endpoints']['mq']['port']).to eq('5672')
      expect(chef_run.node['openstack']['mq']['listen']).to eq('127.0.0.1')
      expect(chef_run.node['rabbitmq']['address']).to eq('127.0.0.1')
      expect(chef_run.node['rabbitmq']['default_user']).to eq('guest')
      expect(chef_run.node['rabbitmq']['default_pass']).to eq('rabbit-pass')
      expect(chef_run.node['rabbitmq']['use_distro_version']).to be_true
    end

    it 'overrides rabbit and openstack image attributes' do
      node.set['openstack']['endpoints']['mq']['bind_interface'] = 'eth0'
      node.set['openstack']['endpoints']['mq']['port'] = '4242'
      node.set['openstack']['mq']['user'] = 'foo'
      node.set['openstack']['mq']['vhost'] = '/bar'

      expect(chef_run.node['openstack']['mq']['listen']).to eq('33.44.55.66')
      expect(chef_run.node['openstack']['endpoints']['mq']['port']).to eq('4242')
      expect(chef_run.node['openstack']['mq']['user']).to eq('foo')
      expect(chef_run.node['openstack']['mq']['vhost']).to eq('/bar')
      expect(chef_run.node['openstack']['mq']['image']['rabbit']['port']).to eq('4242')
      expect(chef_run.node['openstack']['mq']['image']['rabbit']['userid']).to eq('foo')
      expect(chef_run.node['openstack']['mq']['image']['rabbit']['vhost']).to eq('/bar')
    end

    describe 'cluster' do
      before do
        node.set['openstack']['mq'] = {
          'cluster' => true
        }
      end

      it 'overrides cluster' do
        expect(chef_run.node['rabbitmq']['cluster']).to be_true
      end

      it 'overrides erlang_cookie' do
        expect(chef_run.node['rabbitmq']['erlang_cookie']).to eq(
          'erlang-cookie'
        )
      end

      it 'overrides and sorts cluster_disk_nodes' do
        expect(chef_run.node['rabbitmq']['cluster_disk_nodes']).to eq(
          ['guest@host1', 'guest@host2']
        )
      end
    end

    it 'includes rabbit recipes' do
      expect(chef_run).to include_recipe 'rabbitmq'
      expect(chef_run).to include_recipe 'rabbitmq::mgmt_console'
    end

    describe 'lwrps' do
      context 'default mq attributes' do
        it 'does not delete the guest user' do
          expect(chef_run).not_to delete_rabbitmq_user('remove rabbit guest user')
        end
      end

      context 'custom mq attributes' do
        before do
          node.set['openstack']['mq']['user'] = 'not-a-guest'
          node.set['openstack']['mq']['vhost'] = '/foo'
        end

        it 'deletes the guest user' do
          expect(chef_run).to delete_rabbitmq_user(
            'remove rabbit guest user'
          ).with(user: 'guest')
        end

        it 'adds openstack rabbit user' do
          expect(chef_run).to add_rabbitmq_user(
            'add openstack rabbit user'
          ).with(user: 'not-a-guest', password: 'rabbit-pass')
        end

        it 'changes openstack rabbit user password' do
          expect(chef_run).to change_password_rabbitmq_user(
            'change openstack rabbit user password'
          ).with(user: 'not-a-guest', password: 'rabbit-pass')
        end

        it 'adds openstack rabbit vhost' do
          expect(chef_run).to add_rabbitmq_vhost(
            'add openstack rabbit vhost'
          ).with(vhost: '/foo')
        end

        it 'sets openstack user permissions' do
          expect(chef_run).to set_permissions_rabbitmq_user(
            'set openstack user permissions'
          ).with(user: 'not-a-guest', vhost: '/foo', permissions: '.* .* .*')
        end

        it 'sets administrator tag' do
          expect(chef_run).to set_tags_rabbitmq_user(
            'set rabbit administrator tag'
          ).with(user: 'not-a-guest', tag: 'administrator')
        end
      end
    end
  end
end

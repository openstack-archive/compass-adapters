require 'spec_helper'

describe 'ganglia::gmond_collector' do
  {
    "default" => [['default', 18649]],
    "two cluster" => [['default', 18649], ['test', 1234]]
  }.each_pair do |name, cl|
    context "#{name} config" do
      let(:cluster_list) { cl }
      let(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: 'ubuntu',
          version: '12.04'
        )
        cluster_list.each do |cluster, port|
          runner.node.set['ganglia']['clusterport'][cluster] = port
        end
        runner.converge(described_recipe)
      end
      it "writes #{name} gmond.conf" do
        cluster_list.each do |cluster, port|
          expect(chef_run).to create_template("/etc/ganglia/gmond_collector_#{cluster}.conf").with(
            variables: {
              :cluster_name => cluster,
              :port => port
            }
          )
        end
      end
      it "renders gmond.conf with the right port" do
        cluster_list.each do |cluster, port|
          expect(chef_run).to render_file("/etc/ganglia/gmond_collector_#{cluster}.conf").with_content(
              %Q[cluster {
  name = "#{cluster}"
  owner = "unspecified"
  latlong = "unspecified"
  url = "unspecified"
}

/* The host section describes attributes of the host, like the location */
host {
  location = "unspecified"
}

/* You can specify as many udp_recv_channels as you like as well. */
udp_recv_channel {
  port = #{port}
}

/* You can specify as many tcp_accept_channels as you like to share
   an xml description of the state of the cluster */
tcp_accept_channel {
  port = #{port}
}])
        end
      end
      it "writes #{name} gmond init script" do
        cluster_list.each do |cluster, port|
          expect(chef_run).to create_template("/etc/init.d/ganglia-monitor-#{cluster}").with(
            variables: {
              :cluster_name => cluster,
            }
          )
        end
      end
      it "renders #{name} gmond init script with the right cluster name" do
        cluster_list.each do |cluster, port|
          expect(chef_run).to render_file("/etc/init.d/ganglia-monitor-#{cluster}").with_content(
            %Q[NAME=gmond-#{cluster}
DESC="Ganglia Monitor Daemon"
CONF=/etc/ganglia/gmond_collector_#{cluster}.conf
])
        end
      end

      it "starts #{name} gmond" do
        cluster_list.each do |cluster, port|
          expect(chef_run).to start_service("ganglia-monitor-#{cluster}")
        end
      end
    end
  end
end


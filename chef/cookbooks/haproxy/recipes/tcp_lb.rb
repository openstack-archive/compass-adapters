#
# Cookbook Name:: haproxy
# Recipe:: tcp_lb
#
# Copyright 2014, Sam Su
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

node['haproxy']['roles'].each do |role, services|
  services.each do |service|
    node.set['haproxy']['services'][service]['role'] = role
    unless node['haproxy']['enabled_services'].include?(service)
      # node['haproxy']['enabled_services'] << service
      node.set['haproxy']['enabled_services'] = node['haproxy']['enabled_services'] + [service]
    end
    node.save
  end
end

node['haproxy']['services'].each do |name, service|
  unless node['haproxy']['enabled_services'].include?(name)
    next
  end

  if node['haproxy']['choose_backend'].eql?("prefeed")
    pool_members = []
    if node['haproxy'].attribute?("node_mapping")
      node['haproxy']['node_mapping'].each do |nodename, nodeinfo|
        if nodeinfo['roles'].include?(service['role'])
          pool_members << nodename
        end
      end
    end
  else
    pool_members = search(:node, "run_list:role\\[#{service['role']}\\] AND chef_environment:#{node.chef_environment}") || []
    Chef::Log.info("===== search run_list:role\\[#{service['role']}\\] AND chef_environment:#{node.chef_environment}") 
    # load balancer may be in the pool
    pool_members << node if node.run_list.roles.include?(service[:role])
    pool_members = pool_members.sort_by { |node| node.name } unless pool_members.empty?
  end

  # we prefer connecting via local_ipv4 if
  # pool members are in the same cloud
  # TODO refactor this logic into library...see COOK-494
  pool_members.map! do |member|
      Chef::Log.info("processing member ...... #{member}")
    if node['haproxy']['choose_backend'].eql?("prefeed")
      server_ip = node['haproxy']['node_mapping']["#{member}"]['management_ip']
      {:ipaddress => server_ip, :hostname => member}
    else
      server_ip = begin
        if member.attribute?('cloud')
          if node.attribute?('cloud') && (member['cloud']['provider'] == node['cloud']['provider'])
            member['cloud']['local_ipv4']
          else
            member['cloud']['public_ipv4']
          end
        else
          member['ipaddress']
        end
      end
      {:ipaddress => server_ip, :hostname => member['hostname']}
    end
  end

  pool = ["options httpchk #{node['haproxy']['httpchk']}"] if node['haproxy']['httpchk']
  pool = service[:options]
  servers = pool_members.uniq.map do |s|
    # novncproxy cannot to be checked
    if s[:hostname] and s[:ipaddress]
      if name.eql?("novncproxy")
        "#{s[:hostname]} #{s[:ipaddress]}:#{service[:backend_port]}"
      else
        "#{s[:hostname]} #{s[:ipaddress]}:#{service[:backend_port]} check inter 30000 fastinter 1000 rise 2 fall 5"
      end
    end
  end

  haproxy_lb name do
    bind node['haproxy']['incoming_address'] + ':' + service[:frontend_port]
    servers servers
    params pool
  end
end

include_recipe "haproxy::install_#{node['haproxy']['install_method']}"

template "#{node['haproxy']['conf_dir']}/haproxy.cfg" do
  source "haproxy.cfg.erb"
  owner "root"
  group "root"
  mode 00644
  notifies :reload, "service[haproxy]"
  variables(
    :defaults_options => haproxy_defaults_options,
    :defaults_timeouts => haproxy_defaults_timeouts
  )
end

case node["platform_family"]
when "debian"
  cookbook_file "/etc/default/haproxy" do
    source "haproxy-default"
    owner "root"
    group "root"
    mode 00644
    notifies :restart, "service[haproxy]"
  end
end

service "haproxy" do
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end

# Enable haproxy log to file
service "rsyslog" do
  supports :status => true, :restart => true, :start => true, :stop => true
  action :nothing
end

ruby_block "enable haproxy log" do
  block do
    fe = Chef::Util::FileEdit.new('/etc/rsyslog.conf')
    fe.search_file_replace_line(/^\#\$ModLoad\s+imudp/, '$ModLoad imudp')
    fe.write_file
    fe.search_file_replace_line(/^\#\$UDPServerRun\s+514/, '$UDPServerRun 514')
    fe.write_file
    fe.search_file_replace_line(/^\*.emerg\s+\*/, "#*.emerg        *")
    fe.write_file
    haproxylog = "#{node['haproxy']['log']['facilities']}.*  \
                  #{node['haproxy']['log']['file']}"
    if !::File.readlines('/etc/rsyslog.conf').grep(/#{haproxylog}/).any?
      fe.insert_line_after_match('^local7.*', haproxylog)
      fe.write_file
    end
  end
  action :nothing
  subscribes :run, "template[#{node['haproxy']['conf_dir']}/haproxy.cfg]", :immediately
  notifies :restart, "service[rsyslog]", :delayed
end

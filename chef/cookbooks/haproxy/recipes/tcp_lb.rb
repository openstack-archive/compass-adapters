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

node['haproxy']['services'].each do |name, service|
  pool_members = search("node", "role:#{service['role']} AND chef_environment:#{node.chef_environment}") || []

  # load balancer may be in the pool
  pool_members << node if node.run_list.roles.include?(service[:role])

  # we prefer connecting via local_ipv4 if
  # pool members are in the same cloud
  # TODO refactor this logic into library...see COOK-494
  pool_members.map! do |member|
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

  pool = ["options httpchk #{node['haproxy']['httpchk']}"] if node['haproxy']['httpchk']
  pool = service[:options]
  servers = pool_members.uniq.map do |s|
    "#{s[:hostrame]} #{s[:ipaddress]}:#{service[:backend_port]} check inter 2000 rise 2 fall 5"
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

service "haproxy" do
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end


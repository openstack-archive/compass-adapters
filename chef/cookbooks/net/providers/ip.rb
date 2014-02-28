#
# Cookbook Name:: net
# Provider:: net
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
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

def set resource
  cmd = "ifconfig eth0 |grep 'inet addr' | cut -f 2 -d ':' | cut -f 1 -d ' '"
  rc = shell_out(cmd)
  if rc.valid_exit_codes.include?(0)
    net = node['nic']['config']["#{resource.device}"]
    if net['status'].eql?('') or net['status'].nil?
      ip = %x{ifconfig eth0 |grep 'inet addr' | cut -f 2 -d ":" | cut -f 1 -d " "}.split[0].split('.')
      ip[0] = net['network'].split('.')[0]
      ip[1] = net['network'].split('.')[1]
      mac = %x{ifconfig #{resource.device}|grep "HWaddr"}.split()[4]
      node.set['nic']['config']["#{resource.device}"]['ip'] = ip.join('.')
      node.set['nic']['config']["#{resource.device}"]['mac'] = mac
      node.set['nic']['config']["#{resource.device}"]['status'] = "initial"
    else
      Chef::Log.error("Cannot get the device info of #{resource.device}.")
    end
  end
end


action :create do
  set new_resource
  net = node['nic']['config']["#{new_resource.device}"]
  if !net['status'].nil? and net['status'].include?("initial")
    if not ::File.exist?(net['conf'])
      service "network" do
        action :enable
        subscribes :restart, "template[net['conf']]"
      end

      template net['conf'] do
        source "ifcfg.erb"
        mode 00644
        owner "root"
        group "root"
        variables({
          :eth => new_resource.device,
          :mac => net['mac'],
          :ip => net['ip'],
          :netmask => net['netmask']
        })
        notifies :restart, "service[network]", :immediately
      end
      node.set['nic']['config']["#{new_resource.device}"]['status'] = "config"
    end
    new_resource.updated_by_last_action(true)
  end
end


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

def check resource
  cmd = "lspci |grep -i #{resource.vender_name}"
  rc = shell_out(cmd)
  if rc.valid_exit_codes.include?(0)
    driver = node['nic']['vender']['drvier']["#{new_resource.vender_name}"]
    if driver['status'].eql?('')
      node.set['nic']['vender']['drvier']["#{resource.vender_name}"]['status'] = "exist"
    end
  else
    Chef::Log.error("There is not exist the device of #{resource.vender_name}.")  
  end
end

action :prepare do
  package "pciutils" do
    action :upgrade
  end
  new_resource.updated_by_last_action(true)
end

action :install do
  check new_resource
  driver = node['nic']['vender']['drvier']["#{new_resource.vender_name}"]
  if driver['status'].include?("exist")
    #download driver file
    if not ::File.exist?(driver['localpath'])
      remote_file driver['localpath'] do     
        source driver['source']
      end
    end

    execute "load_driver" do
      command node['nic']['vender']['drvier']["#{new_resource.vender_name}"]['load']
      action :nothing
      subscribes :run, "package[nic_driver]", :immediately
    end
   
    # install driver
    package "nic_driver" do
      source driver['localpath']
      action :install
      notifies :run, 'execute[load_driver]', :immediately
    end   
   
    node.set['nic']['vender']['drvier']["#{new_resource.vender_name}"]['status'] = "installed"
    new_resource.updated_by_last_action(true)
  end
end


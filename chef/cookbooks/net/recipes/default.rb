#
# Cookbook Name:: net
# Recipe:: default
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

net_nic "prepare" do
  action :prepare
end


node['nic']['vender']['drvier'].each_key do |vender|
  # Install the driver package
  net_nic vender do
    action :install
  end
end

node['nic']['config'].each_key do |nic|
  net_ip nic.to_s do
    action :create
  end
end

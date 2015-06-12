# Encoding: utf-8
#
# Cookbook Name:: openstack-network
# Recipe:: agent
#
# Copyright 2013, AT&T
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

include_recipe 'openstack-network::l3_agent'
include_recipe 'openstack-network::dhcp_agent'
include_recipe 'openstack-network::metadata_agent'
include_recipe 'openstack-network::openvswitch'

if node['platform_family'] == 'suse'
  if node['lsb']['codename'] == 'UVP'
    include_recipe 'openstack-network::metering_agent'
    include_recipe 'openstack-network::eswitch'
  end
end



#
# Cookbook Name:: net
# Attributes:: default
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
default['nic']['vender']['drvier'] = {
    "Mellanox" => {
      "localpath" => '/tmp/mlnx_en-2.1-1.0.0.0.gfeee0c2.2.6.32_431.el6.x86_64.x86_64.rpm',
      "source" => 'http://10.1.0.201/download/mlnx_en-2.1-1.0.0.0.gfeee0c2.2.6.32_431.el6.x86_64.x86_64.rpm',
      "load" => "rmmod mlx4_core; modprobe mlx4_en",
      "status" => ''
    }
}

default['nic']['config'] = {
    "eth5" => {
      "ip" => '',
      "network" => "10.5.0.0",
      "netmask" => "255.255.0.0",
      "conf" => "/etc/sysconfig/network-scripts/ifcfg-eth5",
      "status" => ''
    },
    "eth6" => {
      "ip" => '',
      "network" => "10.6.0.0",
      "netmask" => "255.255.0.0",
      "conf" => "/etc/sysconfig/network-scripts/ifcfg-eth6",
      "status" => ''
    }
}

#
# Cookbook Name:: rsyslog
# Attributes:: rsyslog
#
# Copyright 2009, Opscode, Inc.
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

default["rsyslog"]["log_dir"]     = "/srv/rsyslog"
default["rsyslog"]["server"]      = false
default["rsyslog"]["protocol"]    = "tcp"
default["rsyslog"]["port"]        = "514"
default["rsyslog"]["server_role"] = "loghost"
default["rsyslog"]["novalog"] = {:"nova-api"=>"/var/log/nova/api.log",                         
                                 :"nova-conductor"=>"/var/log/nova/conductor.log",
                                 :"nova-compute"=>"/var/log/nova/compute.log",
                                 :"nova-scheduler"=>"/var/log/nova/scheduler.log"}
default["rsyslog"]["glancelog"] = {:"glance-api"=>"/var/log/glance/api.log",
                                   :"glance-reg"=>"/var/log/glance/registry.log"}
default["rsyslog"]["cinderlog"] = {:"cinder-api"=>"/var/log/cinder/api.log",
                                   :"cinder-scheduler"=>"/var/log/cinder/scheduler.log",
                                   :"cinder-volume"=>"/var/log/cinder/volume.log"}
default["rsyslog"]["quantumlog"] = {:"quantum-server"=>"/var/log/quantum/server.log",
                                 :"quantum-dhcp"=>"/var/log/quantum/dhcp-agent.log",
                                 :"quantum-l3agent"=>"/var/log/quantum/l3-agent.log",
                                 :"quantum-ovsagent"=>"/var/log/quantum/openvswitch-agent.log"}
default["rsyslog"]["keystonelog"] = {:"keystone"=>"/var/log/keystone/keystone.log"}
default["rsyslog"]["messaginglog"] = {:"rabbitmq"=>"/var/log/rabbitmq/rabbit\@#{node['hostname']}.log"}
default["rsyslog"]["mysqllog"] = {:"mysqld"=>"/var/log/mysqld.log"}

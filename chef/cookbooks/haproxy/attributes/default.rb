#
# Cookbook Name:: haproxy
# Default:: default
#
# Copyright 2010, Opscode, Inc.
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

default['haproxy']['enable_default_http'] = true
default['haproxy']['incoming_address'] = "0.0.0.0"
default['haproxy']['incoming_port'] = 80
default['haproxy']['members'] = [{
  "hostname" => "localhost",
  "ipaddress" => "127.0.0.1",
  "port" => 4000,
  "ssl_port" => 4000
}, {
  "hostname" => "localhost",
  "ipaddress" => "127.0.0.1",
  "port" => 4001,
  "ssl_port" => 4001
}]
default['haproxy']['member_port'] = 8080
default['haproxy']['member_weight'] = 1
default['haproxy']['app_server_role'] = "os-compute-conductor"
default['haproxy']['balance_algorithm'] = "source"
default['haproxy']['enable_ssl'] = false
default['haproxy']['ssl_incoming_address'] = "0.0.0.0"
default['haproxy']['ssl_incoming_port'] = 443
default['haproxy']['ssl_member_port'] = 8443
default['haproxy']['httpchk'] = nil
default['haproxy']['ssl_httpchk'] = nil
default['haproxy']['enable_admin'] = true
default['haproxy']['admin']['address_bind'] = "10.145.88.152"
default['haproxy']['admin']['port'] = 22002
default['haproxy']['enable_stats_socket'] = false
default['haproxy']['stats_socket_path'] = "/var/run/haproxy.sock"
default['haproxy']['stats_socket_user'] = node['haproxy']['user']
default['haproxy']['stats_socket_group'] = node['haproxy']['group']
default['haproxy']['pid_file'] = "/var/run/haproxy.pid"

default['haproxy']['defaults_options'] = ["tcpka", "httpchk", "tcplog"]
default['haproxy']['x_forwarded_for'] = false
default['haproxy']['defaults_timeouts']['connect'] = "5s"
default['haproxy']['defaults_timeouts']['client'] = "50s"
default['haproxy']['defaults_timeouts']['server'] = "50s"
default['haproxy']['cookie'] = nil

default['haproxy']['user'] = "haproxy"
default['haproxy']['group'] = "haproxy"

default['haproxy']['global_max_connections'] = 4096
default['haproxy']['member_max_connections'] = 100
default['haproxy']['frontend_max_connections'] = 2000
default['haproxy']['frontend_ssl_max_connections'] = 2000

default['haproxy']['install_method'] = 'package'
default['haproxy']['conf_dir'] = '/etc/haproxy'

default['haproxy']['source']['version'] = '1.4.22'
default['haproxy']['source']['url'] = 'http://haproxy.1wt.eu/download/1.4/src/haproxy-1.4.22.tar.gz'
default['haproxy']['source']['checksum'] = 'ba221b3eaa4d71233230b156c3000f5c2bd4dace94d9266235517fe42f917fc6'
default['haproxy']['source']['prefix'] = '/usr/local'
default['haproxy']['source']['target_os'] = 'generic'
default['haproxy']['source']['target_cpu'] = ''
default['haproxy']['source']['target_arch'] = ''
default['haproxy']['source']['use_pcre'] = false
default['haproxy']['source']['use_openssl'] = false
default['haproxy']['source']['use_zlib'] = false

default['haproxy']['listeners'] = {
  'listen' => {},
  'frontend' => {},
  'backend' => {}
}

default['haproxy']['services'] = {
  "dashboard_http" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "80",
    "backend_port" => "80",
    "balance" => "source",
    "options" => [ "capture  cookie vgnvisitor= len 32", \
                   "cookie  SERVERID insert indirect nocache", \
                   "mode  http", \
                   "option  forwardfor", \
                   "option  httpchk", \
                   "option  httpclose", \
                   "rspidel  ^Set-cookie:\ IP="]
  },
  "dashboard_https" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "443",
    "backend_port" => "443",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "glance_api" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "9292",
    "backend_port" => "9292",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "glance_registry_cluster" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "9191",
    "backend_port" => "9191",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "keystone_admin" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "35357",
    "backend_port" => "35357",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "keystone_public_internal" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "5000",
    "backend_port" => "5000",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "nova_ec2_api" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "8773",
    "backend_port" => "8773",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "nova_compute_api" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "8774",
    "backend_port" => "8774",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "nova_metadata_api" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "8775",
    "backend_port" => "8775",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "cinder_api" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "8776",
    "backend_port" => "8776",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "ceilometer_api" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "8777",
    "backend_port" => "8777",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "spice" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "6082",
    "backend_port" => "6082",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "neutron_api" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "9696",
    "backend_port" => "9696",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "swift_proxy" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "8080",
    "backend_port" => "8080",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  }
}

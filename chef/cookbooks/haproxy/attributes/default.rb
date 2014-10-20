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

# node['haproxy']['backend'] to deside where service backend sources come from
# if 'prefeed', all services' backend info will be choosen from attribute
# 'node_mapping'; 'prefeed' is suitable for stable and independent services
# if 'autofeed', services' backend info will automaticly learn backend info
# from its chef server.
default['haproxy']['log']['facilities'] = 'local4'
default['haproxy']['log']['file'] = '/var/log/haproxy.log'
default['haproxy']['choose_backend'] = 'autofeed'
default['haproxy']['enable_default_http'] = true
default['haproxy']['incoming_address'] = "0.0.0.0"
default['haproxy']['incoming_port'] = 80
default['haproxy']['members'] = [{
  "hostname" => "localhost",
  "ipaddress" => "127.0.0.1",
  "port" => 4000,
  "ssl_port" => 4000
},
{
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

default['haproxy']['defaults_options'] = ["tcpka", "httpchk", "tcplog", "httplog", "forceclose", "redispatch"]
default['haproxy']['x_forwarded_for'] = false
default['haproxy']['defaults_timeouts']['connect'] = "30s"
default['haproxy']['defaults_timeouts']['check'] = "30s"
#default['haproxy']['defaults_timeouts']['queue'] = "100s"
default['haproxy']['defaults_timeouts']['client'] = "300s"
default['haproxy']['defaults_timeouts']['server'] = "300s"
default['haproxy']['tune']['bufsize'] = 1000000
default['haproxy']['tune']['maxrewrite'] = 1024

default['haproxy']['cookie'] = nil

default['haproxy']['user'] = "haproxy"
default['haproxy']['group'] = "haproxy"

default['haproxy']['global_max_connections'] = 8192
default['haproxy']['member_max_connections'] = 20000
default['haproxy']['frontend_max_connections'] = 4096
default['haproxy']['frontend_ssl_max_connections'] = 4096

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

default['haproxy']['enabled_services'] = [
  "dashboard_http",
  "dashboard_https",
  "glance_api",
  "keystone_admin",
  "keystone_public_internal",
  "nova_compute_api",
  "nova_metadata_api",
  "novncproxy",
  "cinder_api",
  "neutron_api"
]

default['haproxy']['roles'] = {
  "os-identity" => [
    "keystone_admin",
    "keystone_public_internal"
  ],
  "os-dashboard" => [
    "dashboard_http",
    "dashboard_https"
  ],
  "os-compute-controller" => [
    "nova_compute_api",
    "nova_metadata_api",
    "novncproxy"
  ],
  "os-block-storage-controller" => [
    "cinder_api"
  ],
  "os-network-server" => [
    "neutron_api"
  ],
  "os-image" => [
    "glance_api"
  ]
}

default['haproxy']['listeners'] = {
  'listen' => {},
  'frontend' => {},
  'backend' => {}
}

default['haproxy']['services'] = {
  "dashboard_http" => {
    "role" => "os-dashboard",
    "frontend_port" => "80",
    "backend_port" => "80",
    "options" => [ "capture  cookie vgnvisitor= len 32", \
                   "cookie  SERVERID insert indirect nocache", \
                   "mode  http", \
                   "option  forwardfor", \
                   "option  httpchk", \
                   "option  http-server-close", \
                   'rspidel  ^Set-cookie:\ IP='
                  # "appsession csrftoken len 42  timeout 1h"
                 ]
  },
  "dashboard_https" => {
    "role" => "os-dashboard",
    "frontend_port" => "443",
    "backend_port" => "443",
    "balance" => "source",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "glance_api" => {
    "role" => "os-image-api",
    "frontend_port" => "9292",
    "backend_port" => "9292",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog", "balance leastconn" ]
  },
  "glance_registry_cluster" => {
    "role" => "os-image-registry",
    "frontend_port" => "9191",
    "backend_port" => "9191",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog", "balance leastconn" ]
  },
  "keystone_admin" => {
    "role" => "os-identity",
    "frontend_port" => "35357",
    "backend_port" => "35357",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog", "balance leastconn" ]
  },
  "keystone_public_internal" => {
    "role" => "os-identity",
    "frontend_port" => "5000",
    "backend_port" => "5000",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog", "balance leastconn" ]
  },
  "nova_ec2_api" => {
    "role" => "os-compute-api",
    "frontend_port" => "8773",
    "backend_port" => "8773",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "nova_compute_api" => {
    "role" => "os-compute-api",
    "frontend_port" => "8774",
    "backend_port" => "8774",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog", "balance leastconn"]
  },
  "novncproxy" => {
    "role" => "os-compute-vncproxy",
    "frontend_port" => "6080",
    "backend_port" => "6080",
    "balance" => "leastconn",
    #"balance" => "source",
    "options" => [ "option tcpka", "option  http-server-close", "option  tcplog", "balance leastconn"]
  },
  "nova_metadata_api" => {
    "role" => "os-compute-api-metadata",
    "frontend_port" => "8775",
    "backend_port" => "8775",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog", "balance leastconn"]
  },
  "cinder_api" => {
    "role" => "os-block-storage-api",
    "frontend_port" => "8776",
    "backend_port" => "8776",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog", "balance leastconn"]
  },
  "ceilometer_api" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "8777",
    "backend_port" => "8777",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "spice" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "6082",
    "backend_port" => "6082",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  },
  "neutron_api" => {
    "role" => "os-network-server",
    "frontend_port" => "9696",
    "backend_port" => "9696",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog", "balance leastconn"]
  },
  "swift_proxy" => {
    "role" => "os-compute-single-controller",
    "frontend_port" => "8080",
    "backend_port" => "8080",
    "options" => [ "option tcpka", "option  httpchk", "option  tcplog"]
  }
}

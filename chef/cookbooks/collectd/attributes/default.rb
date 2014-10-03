#
# Cookbook Name:: collectd
# Attributes:: default
#
# Copyright 2010, Atari, Inc
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
default[:collectd][:base_dir] = "/var/lib/collectd"
if platform_family?("rhel")
  default[:collectd][:package_name] = ["collectd",
                                        "collectd-amqp",
                                        "collectd-apache",
                                        "collectd-dbi",
                                        "collectd-email",
                                        "collectd-gmond",
                                        "collectd-java",
                                        "collectd-libnotify",
                                        "collectd-liboping",
#                                        "collectd-libvirt",
                                        "collectd-memcache",
                                        "collectd-mysql",
                                        "collectd-nginx",
                                        "collectd-OpenIPMI",
                                        "collectd-perl",
                                        "collectd-postgresql",
                                        "collectd-python",
                                        "collectd-rrdtool",
                                        "collectd-sensors",
                                        "collectd-snmp",
                                        "collectd-varnish"
  ]
  default[:collectd][:yum][:uri] = "http://12.133.183.203/repos/collectd/epel-6"
  default[:collectd][:plugin_dir] = "/usr/lib64/collectd"
  default[:collectd][:config_file] = "/etc/collectd.conf"
elsif platform_family?("debian")
  default[:collectd][:package_name] = ["collectd-core"]
  default[:collectd][:plugin_dir] = "/usr/lib/collectd"
  default[:collectd][:config_file] = "/etc/collectd/collectd.conf"
end
default[:collectd][:types_db] = ["/usr/share/collectd/types.db"]
default[:collectd][:interval] = 10
default[:collectd][:read_threads] = 5

default[:collectd][:collectd_web][:path] = "/srv/collectd_web"
default[:collectd][:collectd_web][:hostname] = "collectd"

default[:collectd][:plugins] = {"cpu"=>{},
                                "cpulinux"=>"",
                                "syslog"=>"",
                                "disk"=>{"Disk"=>"/^[hsv]d[a-f][0-9]?$/", "IgnoreSelected"=>false},
                                "interface"=>"",
                                "load"=>"",
                                "memory"=>"",
                                "match_regex"=>""
                               }
default[:collectd][:included_plugins] = {"kairosdb"=>{}}
default[:collectd][:server][:host] = "metrics"
default[:collectd][:server][:port] = "4242"
default[:collectd][:server][:protocol] = "tcp"
default[:collectd][:server][:lcmetric_names] = "true"
default[:collectd][:server][:diffn_values] = "true"
default[:collectd][:server][:diffn_values_over_time] = "true"
default[:collectd][:mq][:vhost] = "/"

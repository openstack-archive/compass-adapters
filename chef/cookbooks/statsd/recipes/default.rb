#
# Cookbook Name:: statsd
# Recipe:: default
#
# Copyright 2011, Blank Pad Development
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

include_recipe "build-essential"
include_recipe "git"
include_recipe "nodejs"

execute "checkout statsd" do
  command "git clone git://github.com/etsy/statsd"
  creates "/usr/local/statsd"
  cwd "/usr/local"
end

directory "/etc/statsd"

template "/etc/statsd/config.js" do
  source "config.js.erb"
  mode 0644
  variables(
    :port => node[:statsd][:port],
    :graphitePort => node[:statsd][:graphite_port],
    :graphiteHost => node[:statsd][:graphite_host]
  )

  notifies :restart, "service[statsd]"
end

cookbook_file "/usr/local/sbin/statsd" do
  source "statsd"
  mode 0755
end

cookbook_file "/etc/init/statsd.conf" do
  source "upstart.conf"
  mode 0644
end

user "statsd" do
  comment "statsd"
  system true
  shell "/bin/false"
end

service "statsd" do
  provider Chef::Provider::Service::Upstart
  action [ :enable, :start ]
end

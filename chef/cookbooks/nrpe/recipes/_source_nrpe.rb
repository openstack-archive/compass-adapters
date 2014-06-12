#
# Author:: Seth Chisamore <schisamo@getchef.com>
# Cookbook Name:: nrpe
# Recipe:: _source_nrpe
#
# Copyright 2011-2013, Chef Software, Inc..
# Copyright 2012, Webtrends, Inc.
# Copyright 2013-2014, Limelight Networks, Inc.
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

remote_file "#{Chef::Config[:file_cache_path]}/nrpe-#{node['nrpe']['version']}.tar.gz" do
  source "#{node['nrpe']['url']}/nrpe-#{node['nrpe']['version']}.tar.gz"
  checksum node['nrpe']['checksum']
  action :create_if_missing
end

template "/etc/init.d/#{node['nrpe']['service_name']}" do
  source 'nagios-nrpe-server.erb'
  owner node['nrpe']['user']
  group node['nrpe']['group']
  mode  '0755'
end

directory node['nrpe']['conf_dir'] do
  owner node['nrpe']['user']
  group node['nrpe']['group']
  mode  '0755'
end

bash 'compile-nagios-nrpe' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    tar zxvf nrpe-#{node['nrpe']['version']}.tar.gz
    cd nrpe-#{node['nrpe']['version']}
    ./configure --prefix=/usr \
                --sysconfdir=/etc \
                --localstatedir=/var \
                --libexecdir=#{node['nrpe']['plugin_dir']} \
                --libdir=#{node['nrpe']['home']} \
                --enable-command-args \
                --with-nagios-user=#{node['nrpe']['user']} \
                --with-nagios-group=#{node['nrpe']['group']} \
                --with-ssl=/usr/bin/openssl \
                --with-ssl-lib=#{node['nrpe']['ssl_lib_dir']}
    make -s
    make install
  EOH
  creates "#{node['nrpe']['plugin_dir']}/check_nrpe" # perhaps we could replace this with a version check to allow upgrades
end

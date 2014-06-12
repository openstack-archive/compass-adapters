#
# Author:: Seth Chisamore <schisamo@getchef.com>
# Cookbook Name:: nrpe
# Recipe:: _source_plugins
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

plugins_version = node['nrpe']['plugins']['version']

remote_file "#{Chef::Config[:file_cache_path]}/nagios-plugins-#{plugins_version}.tar.gz" do
  source "#{node['nrpe']['plugins']['url']}/nagios-plugins-#{plugins_version}.tar.gz"
  checksum node['nrpe']['plugins']['checksum']
  action :create_if_missing
end

bash 'compile-nagios-plugins' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    tar zxvf nagios-plugins-#{plugins_version}.tar.gz
    cd nagios-plugins-#{plugins_version}
    ./configure --with-nagios-user=#{node['nrpe']['user']} \
                --with-nagios-group=#{node['nrpe']['group']} \
                --prefix=/usr \
                --libexecdir=#{node['nrpe']['plugin_dir']}
    make -s
    make install
  EOH
  creates "#{node['nrpe']['plugin_dir']}/check_users"
end

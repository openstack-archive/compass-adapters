#
# Cookbook Name:: apache2
# Recipe:: mod_auth_openid
#
# Copyright 2008-2013, Opscode, Inc.
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

openid_dev_pkgs = value_for_platform_family(
  'debian'        => %w[automake make g++ apache2-prefork-dev libopkele-dev libopkele3 libtool],
  %w[rhel fedora] => %w[gcc-c++ httpd-devel curl-devel libtidy libtidy-devel sqlite-devel pcre-devel openssl-devel make libtool],
  'arch'          => %w[libopkele],
  'freebsd'       => %w[libopkele pcre sqlite3]
)

make_cmd = value_for_platform_family(
  'freebsd' => { 'default' => 'gmake' },
  'default' => 'make'
)

case node['platform_family']
when 'arch'
  include_recipe 'pacman::default'

  package 'tidyhtml'

  pacman_aur openid_dev_pkgs.first do
    action [:build, :install]
  end
else
  openid_dev_pkgs.each do |pkg|
    package pkg
  end
end

case node['platform_family']
when 'rhel', 'fedora'
  package 'libopkele'
  package 'mod_auth_openid'
when 'debian'
  package 'libapache2-mod-auth-openid'
end

template "#{node['apache']['dir']}/mods-available/authopenid.load" do
  source 'mods/authopenid.load.erb'
  owner  'root'
  group  node['apache']['root_group']
  mode   '0644'
end

apache_module 'authopenid' do
  filename 'mod_auth_openid.so'
end

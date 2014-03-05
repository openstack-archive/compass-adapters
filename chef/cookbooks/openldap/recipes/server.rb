#
# Cookbook Name:: openldap
# Recipe:: server
#
# Copyright 2008-2009, Opscode, Inc.
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
include_recipe "openldap::client"

case node['platform']
when "ubuntu"
  package "db4.8-util" do
    action :upgrade
  end

  directory node['openldap']['preseed_dir'] do
    action :create
    recursive true
    mode 00700
    owner "root"
    group "root"
  end

  cookbook_file "#{node['openldap']['preseed_dir']}/slapd.seed" do
    source "slapd.seed"
    mode 00600
    owner "root"
    group "root"
  end

  package "slapd" do
    response_file "slapd.seed"
    action :upgrade
  end
else
  package "db4.2-util" do
    action :upgrade
  end

  package "slapd" do
    action :upgrade
  end
end

if node['openldap']['tls_enabled'] && node['openldap']['manage_ssl']
  cookbook_file node['openldap']['ssl_cert'] do
    source "ssl/#{node['openldap']['server']}.pem"
    mode 00644
    owner "root"
    group "root"
  end
end

service "slapd" do
  action [:enable, :start]
end

if (node['platform'] == "ubuntu")
  template "/etc/default/slapd" do
    source "default_slapd.erb"
    owner "root"
    group "root"
    mode 00644
  end

  directory "#{node['openldap']['dir']}/slapd.d" do
    recursive true
    owner "openldap"
    group "openldap"
    action :create
  end

  execute "slapd-config-convert" do
    command "slaptest -f #{node['openldap']['dir']}/slapd.conf -F #{node['openldap']['dir']}/slapd.d/"
    user "openldap"
    action :nothing
    notifies :start, "service[slapd]", :immediately
  end

  template "#{node['openldap']['dir']}/slapd.conf" do
    source "slapd.conf.erb"
    mode 00640
    owner "openldap"
    group "openldap"
    notifies :stop, "service[slapd]", :immediately
    notifies :run, "execute[slapd-config-convert]"
  end
else
  case node['platform']
  when "debian","ubuntu"
    template "/etc/default/slapd" do
      source "default_slapd.erb"
      owner "root"
      group "root"
      mode 00644
    end
  end

  template "#{node['openldap']['dir']}/slapd.conf" do
    source "slapd.conf.erb"
    mode 00640
    owner "openldap"
    group "openldap"
    notifies :restart, "service[slapd]"
  end
end

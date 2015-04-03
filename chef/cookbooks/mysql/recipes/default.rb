#
# Cookbook Name:: mysql
# Recipe:: default
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
case node['platform']
when 'suse'
  mysql_repo_package = "http://dev.mysql.com/get/mysql-community-release-sles11-6.noarch.rpm"
  if not node['proxy_url'].nil? and not node['proxy_url'].empty?
    r = execute "download_mysql_repo" do
      command "wget #{mysql_repo_package}"
      cwd Chef::Config[:file_cache_path]
      not_if { ::File.exists?("mysql-community-release-sles11-6.noarch.rpm") }
      environment ({ 'http_proxy' =>  node['proxy_url'], 'https_proxy' => node['proxy_url'] })
    end
    r.run_action(:run)
  else
    r = remote_file "#{Chef::Config[:file_cache_path]}/mysql-community-release-sles11-6.noarch.rpm" do
      source mysql_repo_package
    end
    r.run_action(:create_if_missing)
  end
  r = rpm_package "#{Chef::Config[:file_cache_path]}/mysql-community-release-sles11-6.noarch.rpm"
  r.run_action(:install)
end

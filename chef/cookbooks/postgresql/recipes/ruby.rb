#
# Cookbook Name:: postgresql
# Recipe:: ruby
#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Copyright 2012 Opscode, Inc.
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

# Load the pgdgrepo_rpm_info method from libraries/default.rb
::Chef::Recipe.send(:include, Opscode::PostgresqlHelpers)

node.set['build_essential']['compiletime'] = true
include_recipe "build-essential"
include_recipe "postgresql::client"

if node['postgresql']['enable_pgdg_yum']
  repo_rpm_url, repo_rpm_filename, repo_rpm_package = pgdgrepo_rpm_info
  include_recipe "postgresql::yum_pgdg_postgresql"
  resources("remote_file[#{Chef::Config[:file_cache_path]}/#{repo_rpm_filename}]").run_action(:create)
  resources("package[#{repo_rpm_package}]").run_action(:install)
  ENV['PATH'] = "/usr/pgsql-#{node['postgresql']['version']}/bin:#{ENV['PATH']}"
end

if node['postgresql']['enable_pgdg_apt']
  include_recipe "postgresql::apt_pgdg_postgresql"
  resources("file[remove deprecated Pitti PPA apt repository]").run_action(:delete)
  resources("apt_repository[apt.postgresql.org]").run_action(:add)
end

 
case node['platform_family']
when 'suse'
  if node['local_repo'].nil? or node['local_repo'].empty?
    repo_uri = 'http://download.opensuse.org/repositories/server:/database:/postgresql/SLE_11_SP3/'
    repo_alias = 'postgresql_repo'
    execute 'add postgresql repository' do
      command "zypper addrepo -k --check #{repo_uri} #{repo_alias}"
      not_if { Mixlib::ShellOut.new('zypper repos --export -').run_command.stdout.include? repo_uri }
    end.run_action(:run)
    execute 'add postgresql vendor' do
      command "echo '[#{repo_alias}]\nvendors = #{repo_alias}' > /etc/zypp/vendors.d/#{repo_alias}"
      not_if { ::File.exists?("/etc/zypp/vendors.d/#{repo_alias}") } 
    end.run_action(:run)
  end
end

node['postgresql']['client']['packages'].each do |pg_pack|
  resources("package[#{pg_pack}]").run_action(:install)
end

chef_gem "pg" do
  action :nothing
end.run_action(:install)

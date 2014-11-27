#
# Cookbook Name:: mysql
# Recipe:: ruby
#
# Author:: Jesse Howarth (<him@jessehowarth.com>)
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
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

node.set['build_essential']['compiletime'] = true
include_recipe 'build-essential::default'
include_recipe 'mysql::client'

loaded_recipes = if run_context.respond_to?(:loaded_recipes)
                   run_context.loaded_recipes
                 else
                   node.run_state[:seen_recipes]
                 end

if loaded_recipes.include?('mysql::percona_repo')
  case node['platform_family']
  when 'debian'
    resources('apt_repository[percona]').run_action(:add)
  when 'rhel'
    resources('yum_key[RPM-GPG-KEY-percona]').run_action(:add)
    resources('yum_repository[percona]').run_action(:add)
  end
end

node['mysql']['client']['packages'].each do |name|
  resources("package[#{name}]").run_action(:install)
end

# unknown reason cause chef-client not to honor .gemrc immediately
# even not until timeout is reached, so specify the options explicitly.
if node['local_repo'].nil? or node['local_repo'].empty?
  if node['proxy_url']
    gem_package 'mysql' do
      options("--http-proxy #{node['proxy_url']}")
      action :install
    end
  else
    chef_gem 'mysql'
  end
else
  gem_package 'mysql' do
    options("--clear-sources --source #{node['local_repo']}/gem_repo/")
    action :install
    version '2.9.1'
  end
end

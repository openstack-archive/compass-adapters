#
# Cookbook Name:: compass-rally
# Recipe:: docker
#
# Copyright 2013, Troy Howard
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
platform_options = node['docker']['platform']
major_version = node['platform_version'].split('.').first.to_i

if platform_family?('rhel') && major_version < 7
  include_recipe 'yum-epel'
  docker_packages = ['docker-io']
else
  docker_packages = ['docker']
end

docker_packages.each do |pkg|
  yum_package pkg do
    action :install
  end
end

service "docker" do
  provider platform_options['service_provider']
  supports :status => true, :restart => true, :reload => true
  action [ :start ]
end 

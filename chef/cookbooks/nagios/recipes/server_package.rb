#
# Author:: Seth Chisamore <schisamo@opscode.com>
# Author:: Tim Smith <tsmith@limelight.com>
# Cookbook Name:: nagios
# Recipe:: server_package
#
# Copyright 2011-2013, Opscode, Inc
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

if node['platform_family'] == 'debian'

  # Nagios package requires to enter the admin password
  # We generate it randomly as it's overwritten later in the config templates
  random_initial_password = rand(36**16).to_s(36)

  %w(adminpassword adminpassword-repeat).each do |setting|
    execute "debconf-set-selections::#{node['nagios']['server']['vname']}-cgi::#{node['nagios']['server']['vname']}/#{setting}" do
      command "echo #{node['nagios']['server']['vname']}-cgi #{node['nagios']['server']['vname']}/#{setting} password #{random_initial_password} | debconf-set-selections"
      not_if "dpkg -l #{node['nagios']['server']['vname']}"
    end
  end

end

node['nagios']['server']['packages'].each do |pkg|
  package pkg
end

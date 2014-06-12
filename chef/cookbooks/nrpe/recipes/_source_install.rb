#
# Author:: Tim Smith <tsmith84@gmail.com>
# Cookbook Name:: nrpe
# Recipe:: _source_install
#
# Copyright 2013, Chef Software, Inc..
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

# make sure gcc and make are installed
include_recipe 'build-essential'

pkgs = value_for_platform_family(
    %w(rhel fedora) => %w(openssl-devel make tar),
    'debian' => %w(libssl-dev make tar),
    'gentoo' => [],
    'default' => %w(libssl-dev make tar)
  )

# install the necessary prereq packages for compiling NRPE
pkgs.each do |pkg|
  package pkg do
    action :install
  end
end

user node['nrpe']['user'] do
  system true
end

group node['nrpe']['group'] do
  members [node['nrpe']['user']]
end

# compile both nrpe daemon and the monitoring (aka nagios) plugins
include_recipe 'nrpe::_source_nrpe'
include_recipe 'nrpe::_source_plugins'

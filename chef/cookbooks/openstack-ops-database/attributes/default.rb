# encoding: UTF-8#
#
# Cookbook Name:: openstack-ops-database
# Recipe:: default
#
# Copyright 2013, AT&T Services, Inc.
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

# Platform defaults
case platform_family
when 'fedora', 'rhel' # :pragma-foodcritic: ~FC024 - won't fix this
  default['openstack']['db']['platform']['mysql_python_packages'] = ['MySQL-python']
  default['openstack']['db']['platform']['postgresql_python_packages'] = ['python-psycopg2']
when 'suse'
  default['openstack']['db']['platform']['mysql_python_packages'] = ['python-mysql']
  default['openstack']['db']['platform']['postgresql_python_packages'] = ['python-psycopg2']
  if node['lsb']['codename'] == 'UVP'
    default['openstack']['secret']['nova'] = 'ComputeNova123'
    default['openstack']['secret']['horizon'] = 'DashboardHorizon123'
    default['openstack']['secret']['keystone'] = 'IdentityKeystone123'
    default['openstack']['secret']['glance'] = 'ImageGlance123'
    default['openstack']['secret']['ceilometer'] = 'TelemetryCeilometer123'
    default['openstack']['secret']['neutron'] = 'NetworkNeutron123'
    default['openstack']['secret']['cinder'] = 'BlockStorageCinder123'
    default['openstack']['secret']['heat'] = 'OrchestrationHeat123'
    default['openstack']['secret']['admin'] = 'AdminPassword123'
    default['openstack']['secret']['demo'] = 'DemoPassword123'
  end
when 'debian'
  default['openstack']['db']['platform']['mysql_python_packages'] = ['python-mysqldb']
  default['openstack']['db']['platform']['postgresql_python_packages'] = ['python-psycopg2']
end

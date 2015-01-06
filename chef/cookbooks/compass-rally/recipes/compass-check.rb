#
# Cookbook Name:: compass-rally
# Recipe:: compass-check
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'uri'

class ::Chef::Recipe
  include ::Openstack
end

%w[ /opt /opt/compass /opt/compass/rally
  /opt/compass/rally/deployment].each do |path|
  directory path do
    owner "root"
    group "root"
    mode "0755"
  end
end

remote_directory "/opt/compass/rally/scenarios" do
  mode "0755"
  action :create_if_missing
end

cookbook_file "check_health.py" do
  path "/opt/compass/check_health.py"
end

# Figure out identiy URL
identity_admin_ep = endpoint 'identity-api'
admin = node['openstack']['identity']['admin_user'] || 'admin'
pass = node['openstack']['identity']['users'][admin]['password']

deployment_name = '/opt/compass/rally/deployment/' +
  node.name.split('.')[-1] + '.json'

template deployment_name do
  source 'deployment.json.erb'
  variables(
            user: admin,
            password: pass,
            url: identity_admin_ep,
            tenant: 'admin')
  action :create_if_missing
end

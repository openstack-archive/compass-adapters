#
# Cookbook Name:: nginx_simplecgi
# Recipe:: init
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

if node[:nginx_simplecgi][:php]
  template '/etc/init.d/phpwrap_dispatcher' do
    source 'wrap.init.erb'
    owner 'root'
    group 'root'
    mode '0755'
    variables(
      :kind => 'php',
      :exec => '/usr/local/bin/phpwrap_dispatcher',
      :pid_file => File.join(
        node[:nginx_simplecgi][:dispatcher_directory],
        'phpwrap_dispatcher.pid'
      )
    )
  end

  service 'phpwrap_dispatcher' do
    supports :status => true, :restart => true, :reload => false
    action [:enable, :start]
  end
end

if node[:nginx_simplecgi][:cgi]
  template '/etc/init.d/cgiwrap_dispatcher' do
    source 'wrap.init.erb'
    owner 'root'
    group 'root'
    mode '0755'
    variables(
      :kind => 'cgi',
      :exec => '/usr/local/bin/cgiwrap_dispatcher',
      :pid_file => File.join(
        node[:nginx_simplecgi][:dispatcher_directory],
        'cgiwrap_dispatcher.pid'
      )
    )
  end

  service 'cgiwrap_dispatcher' do
    supports :status => true, :restart => true, :reload => false
    action [:enable, :start]
  end
end

#
# Cookbook Name:: nginx_simplecgi
# Recipe:: upstart
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
  template '/etc/init/nginx_phpwrap_dispatcher.conf' do
    source 'upstart-phpwrap_dispatcher.erb'
    variables(
      :nginx_user => node[:nginx][:user],
      :nginx_group => node[:nginx][:group] || node[:nginx][:user],
      :dispatch_dir => node[:nginx_simplecgi][:dispatcher_directory],
      :dispatch_procs => node[:nginx_simplecgi][:dispatcher_processes],
      :php_cgi_bin => node[:nginx_simplecgi][:php_cgi_bin]
    )
  end

  service 'nginx_phpwrap_dispatcher' do
    provider Chef::Provider::Service::Upstart
    supports :status => true, :restart => true, :reload => true
    action [:enable, :start]
  end
end

if node[:nginx_simplecgi][:cgi]
  template '/etc/init/nginx_cgiwrap_dispatcher.conf' do
    source 'upstart-cgiwrap_dispatcher.erb'
    variables(
      :dispatch_dir => node[:nginx_simplecgi][:dispatcher_directory],
      :nginx_user => node[:nginx][:user],
      :nginx_group => node[:nginx][:group] || node[:nginx][:user]
    )
  end

  service 'nginx_cgiwrap_dispatcher' do
    provider Chef::Provider::Service::Upstart
    supports :status => true, :restart => true, :reload => true
    action [:enable, :start]
  end
end

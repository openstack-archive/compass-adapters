#
# Cookbook Name:: rabbitmq
# Recipe:: default
#
# Copyright 2009, Benjamin Black
# Copyright 2009-2013, Opscode, Inc.
# Copyright 2012, Kevin Nuckolls <kevin.nuckolls@gmail.com>
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

#
class Chef::Resource
  include Opscode::RabbitMQ
end

include_recipe 'erlang'

## Install the package
case node['platform_family']
when 'debian'
  # installs the required setsid command -- should be there by default but just in case
  package 'util-linux'

  if node['rabbitmq']['use_distro_version'] or (not node['local_repo'].nil? and not node['local_repo'].empty?)
    package 'rabbitmq-server' do
      action :upgrade
    end
  else
    # we need to download the package
    deb_package = "https://www.rabbitmq.com/releases/rabbitmq-server/v#{node['rabbitmq']['version']}/rabbitmq-server_#{node['rabbitmq']['version']}-1_all.deb"
    if not node['proxy_url'].nil? and not node['proxy_url'].empty?
      execute "download_mod-rabbitmq-server_#{node['rabbitmq']['version']}-1_all.deb" do
        command "wget #{deb_package}"
        cwd Chef::Config['file_cache_path']
        not_if { ::File.exists?("rabbitmq-server_#{node['rabbitmq']['version']}-1_all.deb") }
        environment ({ 'http_proxy' =>  node['proxy_url'], 'https_proxy' => node['proxy_url'] })
      end
    else
      remote_file "#{Chef::Config[:file_cache_path]}/rabbitmq-server_#{node['rabbitmq']['version']}-1_all.deb" do
        source deb_package
        action :create_if_missing
      end
    end
    dpkg_package "#{Chef::Config[:file_cache_path]}/rabbitmq-server_#{node['rabbitmq']['version']}-1_all.deb"
  end

  if node['rabbitmq']['logdir']
    directory node['rabbitmq']['logdir'] do
      owner 'rabbitmq'
      group 'rabbitmq'
      mode '775'
      recursive true
    end
  end

  directory node['rabbitmq']['mnesiadir'] do
    owner 'rabbitmq'
    group 'rabbitmq'
    mode '775'
    recursive true
  end

  template "#{node['rabbitmq']['config_root']}/rabbitmq-env.conf" do
    source 'rabbitmq-env.conf.erb'
    owner 'root'
    group 'root'
    mode 00644
    notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :delayed
  end

  template "#{node['rabbitmq']['config_root']}/rabbitmq.config" do
    source 'rabbitmq.config.erb'
    owner 'root'
    group 'root'
    mode 00644
    variables(
      :kernel => format_kernel_parameters
    )
    notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :delayed
  end

  # Configure job control
  if node['rabbitmq']['job_control'] == 'upstart'
    # We start with stock init.d, remove it if we're not using init.d, otherwise leave it alone
    service node['rabbitmq']['service_name'] do
      action [:stop]
      only_if { File.exists?('/etc/init.d/rabbitmq-server') }
    end

    execute 'remove rabbitmq init.d command' do
      command 'update-rc.d -f rabbitmq-server remove'
    end

    file '/etc/init.d/rabbitmq-server' do
      action :delete
    end

    template "/etc/init/#{node['rabbitmq']['service_name']}.conf" do
      source 'rabbitmq.upstart.conf.erb'
      owner 'root'
      group 'root'
      mode 0644
      variables(:max_file_descriptors => node['rabbitmq']['max_file_descriptors'])
    end

    service node['rabbitmq']['service_name'] do
      provider Chef::Provider::Service::Upstart
      action [:enable, :start]
    end

    ruby_block "service #{node['rabbitmq']['service_name']} restart if necessary" do
      block do
        Chef::Log.info("service rabbitmq restart")
      end
      not_if "status #{node['rabbitmq']['service_name']} | grep -q '^$1 start' > /dev/null"
      notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :immediately
    end

  end

  ## You'll see setsid used in all the init statements in this cookbook. This
  ## is because there is a problem with the stock init script in the RabbitMQ
  ## debian package (at least in 2.8.2) that makes it not daemonize properly
  ## when called from chef. The setsid command forces the subprocess into a state
  ## where it can daemonize properly. -Kevin (thanks to Daniel DeLeo for the help)
  if node['rabbitmq']['job_control'] == 'initd'
    service node['rabbitmq']['service_name'] do
      start_command 'setsid /etc/init.d/rabbitmq-server start'
      stop_command 'setsid /etc/init.d/rabbitmq-server stop'
      restart_command 'setsid /etc/init.d/rabbitmq-server restart'
      status_command 'setsid /etc/init.d/rabbitmq-server status'
      supports :status => true, :restart => true
      action [:enable, :start]
    end

    ruby_block "service #{node['rabbitmq']['service_name']} restart if necessary" do
      block do
        Chef::Log.info("service rabbitmq restart")
      end
      not_if "setsid /etc/init.d/rabbitmq-server status"
      notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :immediately
    end
  end

when 'rhel', 'fedora'
  # This is needed since Erlang Solutions' packages provide "esl-erlang"; this package just requires "esl-erlang" and provides "erlang".
  if node['erlang']['install_method'] == 'esl'
    remote_file "#{Chef::Config[:file_cache_path]}/esl-erlang-compat.rpm" do
      source 'https://github.com/jasonmcintosh/esl-erlang-compat/blob/master/rpmbuild/RPMS/noarch/esl-erlang-compat-R14B-1.el6.noarch.rpm?raw=true'
    end
    rpm_package "#{Chef::Config[:file_cache_path]}/esl-erlang-compat.rpm"
  end

  if node['rabbitmq']['use_distro_version'] or (not node['local_repo'].nil? and not node['local_repo'].empty?)
    package 'rabbitmq-server' do
      action :upgrade
    end
  else
    # We need to download the rpm
    rpm_package = "https://www.rabbitmq.com/releases/rabbitmq-server/v#{node['rabbitmq']['version']}/rabbitmq-server-#{node['rabbitmq']['version']}-1.noarch.rpm"
    if not node['proxy_url'].nil? and not node['proxy_url'].empty?
      execute "download_mod-rabbitmq-server_#{node['rabbitmq']['version']}-1_all.deb" do
        command "wget #{rpm_package}"
        cwd Chef::Config['file_cache_path']
        not_if { ::File.exists?("rabbitmq-server_#{node['rabbitmq']['version']}-1.noarch.rpm") }
        environment ({ 'http_proxy' =>  node['proxy_url'], 'https_proxy' => node['proxy_url'] })
      end
    else
      remote_file "#{Chef::Config[:file_cache_path]}/rabbitmq-server-#{node['rabbitmq']['version']}-1.noarch.rpm" do
        source rpm_package
        action :create_if_missing
      end
    end
    rpm_package "#{Chef::Config[:file_cache_path]}/rabbitmq-server-#{node['rabbitmq']['version']}-1.noarch.rpm"
  end

  if node['rabbitmq']['logdir']
    directory node['rabbitmq']['logdir'] do
      owner 'rabbitmq'
      group 'rabbitmq'
      mode '775'
      recursive true
    end
  end

  directory node['rabbitmq']['mnesiadir'] do
    owner 'rabbitmq'
    group 'rabbitmq'
    mode '775'
    recursive true
  end

  template "#{node['rabbitmq']['config_root']}/rabbitmq-env.conf" do
    source 'rabbitmq-env.conf.erb'
    owner 'root'
    group 'root'
    mode 00644
    notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :delayed
  end

  template "#{node['rabbitmq']['config_root']}/rabbitmq.config" do
    source 'rabbitmq.config.erb'
    owner 'root'
    group 'root'
    mode 00644
    variables(
      :kernel => format_kernel_parameters
    )
    notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :delayed
  end

  service node['rabbitmq']['service_name'] do
    supports :status => true, :restart => true
    action [:enable, :start]
  end

  ruby_block "service #{node['rabbitmq']['service_name']} restart if necessary" do
    block do
      Chef::Log.info("service rabbitmq restart")
    end
    not_if "service #{node['rabbitmq']['service_name']} status"
    notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :immediately
  end

when 'suse'
  # rabbitmq-server-plugins needs to be first so they both get installed
  # from the right repository. Otherwise, zypper will stop and ask for a
  # vendor change.
  if node['lsb']['codename'] == 'UVP'
    package 'rabbitmq'

    template "/etc/sysconfig/#{node['rabbitmq']['service_name']}"  do
      source "#{node['rabbitmq']['service_name']}.sysconfig.erb"
      owner 'root'
      group 'root'
      mode 0644
    end

    template "/etc/init.d/#{node['rabbitmq']['service_name']}" do
      source "#{node['rabbitmq']['service_name']}.uvp.erb"
      owner 'root'
      group 'root'
      mode 0755
    end
  else
    package 'rabbitmq-server-plugins'
    package 'rabbitmq-server'
  end

  if node['rabbitmq']['logdir']
    directory node['rabbitmq']['logdir'] do
      owner 'rabbitmq'
      group 'rabbitmq'
      mode '775'
      recursive true
    end
  end

  directory node['rabbitmq']['mnesiadir'] do
    owner 'rabbitmq'
    group 'rabbitmq'
    mode '775'
    recursive true
  end

  if node['rabbitmq']['cluster']
    node['rabbitmq']['cluster_disk_nodes'].each do | cluster_disk_node |
      node_dir =  "#{node['rabbitmq']['mnesiadir']}/#{cluster_disk_node}"
      directory node_dir do
        owner 'rabbitmq'
        group 'rabbitmq'
        mode '775'
        recursive true
      end
    end
  end

  template "#{node['rabbitmq']['config_root']}/rabbitmq-env.conf" do
    source 'rabbitmq-env.conf.erb'
    owner 'root'
    group 'root'
    mode 00644
    notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :delayed
  end

  template "#{node['rabbitmq']['config_root']}/rabbitmq.config" do
    source 'rabbitmq.config.erb'
    owner 'root'
    group 'root'
    mode 00644
    variables(
      :kernel => format_kernel_parameters
    )
    notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :delayed
  end

  template "/etc/sysconfig/erlang" do
    source 'sysconfig.erlang.erb'
    owner 'root'
    group 'root'
    mode 00644
    notifies :restart, "service[epmd]", :delayed
  end

  service 'epmd' do
    supports :status => true, :restart => true
    action [:enable, :start]
  end

  ruby_block "service epmd restart if necessary" do
    block do
      Chef::Log.info("service epmd restart")
    end
    not_if "service epmd status"
    notifies :restart, "service[epmd]", :immediately
  end

  service node['rabbitmq']['service_name'] do
    supports :status => true, :restart => true
    action [:enable, :start]
  end

  ruby_block "service #{node['rabbitmq']['service_name']} restart if necessary" do
    block do
      Chef::Log.info("service #{node['rabbitmq']['service_name']} restart")
    end
    not_if "service #{node['rabbitmq']['service_name']} status"
    notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :immediately
  end
when 'smartos'
  package 'rabbitmq'

  service 'epmd' do
    supports :status => true, :restart => true
    action [:enable, :start]
  end

  if node['rabbitmq']['logdir']
    directory node['rabbitmq']['logdir'] do
      owner 'rabbitmq'
      group 'rabbitmq'
      mode '775'
      recursive true
    end
  end

  directory node['rabbitmq']['mnesiadir'] do
    owner 'rabbitmq'
    group 'rabbitmq'
    mode '775'
    recursive true
  end

  template "#{node['rabbitmq']['config_root']}/rabbitmq-env.conf" do
    source 'rabbitmq-env.conf.erb'
    owner 'root'
    group 'root'
    mode 00644
    notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :delayed
  end

  template "#{node['rabbitmq']['config_root']}/rabbitmq.config" do
    source 'rabbitmq.config.erb'
    owner 'root'
    group 'root'
    mode 00644
    variables(
      :kernel => format_kernel_parameters
    )
    notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :delayed
  end

  service node['rabbitmq']['service_name'] do
    supports :status => true, :restart => true
    action [:enable, :start]
  end

  ruby_block "service #{node['rabbitmq']['service_name']} restart if necessary" do
    block do
      Chef::Log.info("service rabbitmq restart")
    end
    not_if "service #{node['rabbitmq']['service_name']} status"
    notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :immediately
  end
end

if File.exists?(node['rabbitmq']['erlang_cookie_path'])
  existing_erlang_key =  File.read(node['rabbitmq']['erlang_cookie_path']).strip
else
  existing_erlang_key = ''
end

if node['rabbitmq']['cluster'] && (node['rabbitmq']['erlang_cookie'] != existing_erlang_key)
  template node['rabbitmq']['erlang_cookie_path'] do
    source 'doterlang.cookie.erb'
    owner 'rabbitmq'
    group 'rabbitmq'
    mode 00400
    notifies :restart, "service[#{node['rabbitmq']['service_name']}]", :immediately
    notifies :run, 'execute[reset-node]', :immediately
  end

  # Need to reset for clustering #
  execute 'reset-node' do
    command "#{node['rabbitmq']['binary_dir']}/rabbitmqctl stop_app && #{node['rabbitmq']['binary_dir']}/rabbitmqctl reset && #{node['rabbitmq']['binary_dir']}/rabbitmqctl start_app"
    action :nothing
  end
end

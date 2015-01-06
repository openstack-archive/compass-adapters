#
# Cookbook Name:: compass-rally
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "python"

node['stackforge']['rally']['required_packages'].each do |pkg|
 package pkg
end

python_virtualenv node['stackforge']['rally']['vars']['virtualenv_dir'] do
  action :create
end

python_pip "pbr" do
  virtualenv node['stackforge']['rally']['vars']['virtualenv_dir'] 
  action :install
end


python_pip 'tox' do
  virtualenv  node['stackforge']['rally']['vars']['virtualenv_dir']
  version '1.6.1'
  action :install
end


python_pip 'MySQL-python' do
  virtualenv  node['stackforge']['rally']['vars']['virtualenv_dir']
  action :install
end


# Note: This does not work. pbr requires version from git remote
#remote_file "Copy Rally source from Github" do
#  path "/tmp/rally-src.zip"
#  source node['stackforge']['rally']['vars']['rally_src_zip']
#  owner 'root'
#  group 'root'
#  mode 0755
#end

# unzip src
#bash "get_rally_src" do
#  code <<-EOL
#   mkdir -p /tmp/rally-src
#   unzip -o /tmp/rally-src.zip -d /tmp/rally-src
#  EOL
#end

#git "/tmp/" do
#  repository "git://github.com/stackforge/rally.git"
#  revision "master"
#  action :sync
#end

virtualenv = node['stackforge']['rally']['vars']['virtualenv_dir']

RALLY_DATABASE_DIR=node['stackforge']['rally']['vars']['virtualenv_dir'] + "/database"
RALLY_CONFIGURATION_DIR="/etc/rally"
RALLY_DB=node['mysql']['bind_address'] + ":#{node['mysql']['port']}" 

bash "install_rally" do
  code <<-EOL
 if [ -f "/opt/rally/bin/rally" ]; then
    echo "Rally is already installed. Skipped reinstall"
 else
   source "#{virtualenv}/bin/activate"
   mkdir -p /tmp/rally-src
   cd /tmp/rally-src
   rm -rf /tmp/rally-src/*
   git clone https://github.com/stackforge/rally.git
   cd rally
   python setup.py install


   mkdir -p #{RALLY_DATABASE_DIR} #{RALLY_CONFIGURATION_DIR}
   sed 's|#connection=<None>|connection=mysql://rally:rally@'#{RALLY_DB}'/rally|' etc/rally/rally.conf.sample > #{RALLY_CONFIGURATION_DIR}/rally.conf
   rally-manage db recreate
   chmod -R go+w #{RALLY_DATABASE_DIR}
   sleep 200
 fi
  EOL
  cwd "/tmp"
  tag = 'rally_node'
  node.tags << tag unless node.tags.include?(tag)
end

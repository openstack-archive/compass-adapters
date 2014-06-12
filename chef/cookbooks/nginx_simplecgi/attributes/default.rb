#
# Cookbook Name:: nginx_simplecgi
# Attributes:: default
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

default[:nginx_simplecgi] = Mash.new
# Enable CGI dispatcher
default[:nginx_simplecgi][:cgi] = false
# Enable PHP dispatcher
default[:nginx_simplecgi][:php] = false
# Directory to contain dispatcher socket and pid file
default[:nginx_simplecgi][:dispatcher_directory] = '/var/run/nginx'
# Number of dispatcher process to handle requests
default[:nginx_simplecgi][:dispatcher_processes] = 4
# Location of PHP CGI executable
default[:nginx_simplecgi][:php_cgi_bin] = '/usr/bin/php-cgi'
# Type of init (:upstart, :runit, :bluepill, :monit)
default[:nginx_simplecgi][:init_type] = :upstart

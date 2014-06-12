#
# Cookbook Name:: nginx_simplecgi
# Recipe:: default
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

# By default, nothing is setup. This allows cookbooks dependent on
# simplecgi to define how they would like the setup to occur without
# relying on attributes being set directly within nginx_simplecgi

if node[:nginx_simplecgi][:cgi] || node[:nginx_simplecgi][:php]
  include_recipe 'nginx_simplecgi::setup'
end

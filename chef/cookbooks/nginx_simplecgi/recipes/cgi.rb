#
# Cookbook Name:: nginx_simplecgi
# Recipe:: cgi
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

template '/usr/local/bin/cgiwrap_dispatcher' do
  source 'cgiwrap-dispatcher.erb'
  variables(
    :dispatch_dir => node[:nginx_simplecgi][:dispatcher_directory],
    :dispatch_procs => node[:nginx_simplecgi][:dispatcher_processes]
  )
  mode '0755'
end

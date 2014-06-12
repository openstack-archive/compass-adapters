#
# Cookbook Name:: nginx_simplecgi
# Recipe:: bluepill
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

include_recipe 'bluepill'

wrap_types = [
  node[:nginx_simplecgi][:php] ? :php : nil,
  node[:nginx_simplecgi][:cgi] ? :cgi : nil
].compact

wrap_types.each do |kind|
  template File.join(node[:bluepill][:conf_dir], "#{kind}dispatcher.pill") do
    source 'wrap.pill.erb'
    mode 0644
    variables(
      :pid_file => File.join(
        node[:nginx_simplecgi][:dispatcher_directory],
        "#{kind}wrap_dispatcher.pid"
      ),
      :pill_name => "#{kind}wrap_dispatcher",
      :working_dir => node[:nginx_simplecgi][:dispatcher_directory],
      :exec => "/usr/local/bin/#{kind}wrap_dispatcher"
    )
  end

  bluepill_service "#{kind}wrap_dispatcher" do
    action [:enable, :load]
  end
end

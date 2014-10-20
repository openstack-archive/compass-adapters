#
# Cookbook Name:: collectd
# Recipe:: client
#
# Copyright 2014, Huawei Technologies Co,ltd
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
include_recipe "collectd"

case node["platform_family"]
when "rhel"
  if node["collectd"].attribute?("rhel")
    if not node["collectd"]["rhel"]["plugins"].nil?
      node.override["collectd"]["plugins"]=node["collectd"]["rhel"]["plugins"].to_hash
    end
  end
when "debian"
  if node["collectd"].attribute?("debian")
    if not node["collectd"]["debian"]["plugins"].nil?
      node.override["collectd"]["plugins"]=node["collectd"]["debian"]["plugins"].to_hash
    end
  end
end

node["collectd"]["plugins"].each_pair do |plugin_key, options|
  collectd_plugin plugin_key do
    options  options
  end
end

#for python plugins or more complicated ones, use seperate recipe to deploy them
if node["collectd"].attribute?("included_plugins") and not node["collectd"]["included_plugins"].nil?
  node["collectd"]["included_plugins"].each_pair do |plugin_key, options|
    include_recipe("collectd::#{plugin_key}")
  end
end

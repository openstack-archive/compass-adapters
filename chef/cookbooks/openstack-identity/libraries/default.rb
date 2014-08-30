# encoding: UTF-8
# #
# # Cookbook Name:: openstack-identity
# # libraries::master_election
# #
# # Author: sam.su@huawei.com
# #
# # Licensed under the Apache License, Version 2.0 (the 'License');
# # you may not use this file except in compliance with the License.
# # You may obtain a copy of the License at
# #
# #     http://www.apache.org/licenses/LICENSE-2.0
# #
# # Unless required by applicable law or agreed to in writing, software
# # distributed under the License is distributed on an 'AS IS' BASIS,
# # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# # See the License for the specific language governing permissions and
# # limitations under the License.
# #
#
def node_election(role, tag, chef_environment = nil)
  chef_environment = chef_environment || node.chef_environment
  master = search(:node, "run_list:role\\[#{role}\\] AND \
                  chef_environment:#{chef_environment} AND \
                  tags:#{tag}") || []
  if master.empty?
    nodes = search(:node, "run_list:role\\[#{role}\\] AND \
                   chef_environment:#{chef_environment}") || []
    nodes = nodes.sort_by { |node| node.name } unless nodes.empty?
    if node.name.eql?(nodes.first.name)
      node.tags << tag unless node.tags.include?(tag)
      node.save
    end
    return nodes.first
  else
    return master.first
  end
end

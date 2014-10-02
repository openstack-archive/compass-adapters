
def keepalived_master(role, tag, chef_environment = node.chef_environment)
  chef_environment = chef_environment || node.chef_environment
  master = search(:node, "run_list:role\\[#{role}\\] AND \
                  chef_environment:#{chef_environment} AND \
                  tags:#{tag}") || []
  master = master.sort_by { |node| node.name } unless master.empty?
  if master.empty?
    nodes = search(:node, "run_list:role\\[#{role}\\] AND \
                   chef_environment:#{chef_environment}") || []
    if nodes.empty?
      Chef::Log.error("Cannot find the role #{role} in the environment #{chef_environment}\n")
    end
    nodes = nodes.sort_by { |node| node.name } unless nodes.empty?
    if node.name.eql?(nodes.first.name)
      node.tags << tag unless node.tags.include?(tag)
      node.save
    end
    return nodes.first
  else
    if master.length.eql?(1)
      return master.first
    else
      head, *tail = master
      for m in tail
        print node,m
        m.tags.delete(tag)
        m.save
      end
      return head
    end
  end
end

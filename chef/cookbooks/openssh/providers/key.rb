require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :create do
  ssh_keygen_node = node_election(new_resource.role, 'ssh_keygen')
  a = node['openssh']['shared']['private_key']
  if node.name.eql?(ssh_keygen_node.name) and node['openssh']['shared']['private_key'].nil?
    unless ::File.exist?(new_resource.private_key)
      cmd = "ssh-keygen -t rsa -q -f #{new_resource.private_key} -P ''"
      rc = shell_out(cmd)
    end
    pri_key = ::File.read(new_resource.private_key)
    pub_key = ::File.read(new_resource.public_key)
    node.set['openssh']['shared']['private_key'] = pri_key
    node.set['openssh']['shared']['public_key'] = pub_key
    node.set['openssh']['shared']['authorized_key'] = pub_key
    node.save
    if ::File.exist?(new_resource.authorized_key)
      ruby_block new_resource.authorized_key do
        block do
          auth_file = Chef::Util::FileEdit.new(new_resource.authorized_key)
          auth_file.insert_line_if_no_match(pub_key, pub_key)
          auth_file.write_file
        end
      end
    else
      file "#{new_resource.authorized_key}" do
        content node['openssh']['shared']['authorized_key']
        owner   new_resource.username
        group   new_resource.username
        mode    00600
      end
    end
  elsif !node.name.eql?(ssh_keygen_node.name) && node['openssh']['shared']['private_key'].nil?
    directory "#{new_resource.home}/.ssh for ssh keys" do
      path "#{new_resource.home}/.ssh"
      owner new_resource.username
      group new_resource.username
      mode "0700"
    end
    if ssh_keygen_node.attribute?('openssh')
      %w{private_key public_key authorized_key}.each do |key|
        unless ssh_keygen_node['openssh']['shared']["#{key}"].nil?
          node.set['openssh']['shared']["#{key}"] = ssh_keygen_node['openssh']['shared']["#{key}"]
          node.save
          file eval("new_resource.#{key}") do
            content node['openssh']['shared']["#{key}"]
            owner   new_resource.username
            group   new_resource.username
            mode    00600
          end
        end
      end
    end
  #else
    ## TODO:
  end
end


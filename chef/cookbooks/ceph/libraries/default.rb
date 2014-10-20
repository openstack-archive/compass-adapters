require 'ipaddr'
require 'json'
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

def crowbar?
  !defined?(Chef::Recipe::Barclamp).nil?
end

def mon_nodes
  if crowbar?
    mon_roles = search(:role, 'name:crowbar-* AND run_list:role\[ceph*-mon\]')
    unless mon_roles.empty?
      search_string = mon_roles.map { |role_object| 'roles:' + role_object.name }.join(' OR ')
      search_string = "(#{search_string}) AND ceph_config_environment:#{node['ceph']['config']['environment']}"
    end
  else
    #search_string = "ceph_is_mon:true AND chef_environment:#{node.chef_environment}"
    search_string = "ceph_is_mon:true AND ceph_config_fsid:#{node["ceph"]["config"]["fsid"]}"
  end

  if use_cephx? && !node['ceph']['encrypted_data_bags']
    search_string = "(#{search_string}) AND (ceph_bootstrap_osd_key:*)"
  end
  search(:node, search_string)
end

def osd_secret
  if node['ceph']['encrypted_data_bags']
    secret = Chef::EncryptedDataBagItem.load_secret(node['ceph']['osd']['secret_file'])
    return Chef::EncryptedDataBagItem.load('ceph', 'osd', secret)['secret']
  else
    return mon_nodes[0]['ceph']['bootstrap_osd_key']
  end
end

# If public_network is specified
# we need to search for the monitor IP
# in the node environment.
# 1. We look if the network is IPv6 or IPv4
# 2. We look for a route matching the network
# 3. We grab the IP and return it with the port
def find_node_ip_in_network(network, nodeish = nil)
  nodeish = node unless nodeish
  net = IPAddr.new(network)
  nodeish['network']['interfaces'].each do |_iface, addrs|
    addresses = addrs['addresses'] || []
    addresses.each do |ip, params|
      return ip_address_to_ceph_address(ip, params) if ip_address_in_network?(ip, params, net)
    end
  end
  nil
end

def ip_address_in_network?(ip, params, net)
  if params['family'] == 'inet'
    net.include?(ip) && params.key?('broadcast')     # is primary ip on iface
  elsif params['family'] == 'inet6'
    net.include?(ip)
  else
    false
  end
end

def ip_address_to_ceph_address(ip, params)
  if params['family'].eql?('inet6')
    return "[#{ip}]:6789"
  elsif params['family'].eql?('inet')
    return "#{ip}:6789"
  end
end

def mon_addresses
  mon_ips = []

  if File.exist?("/var/run/ceph/ceph-mon.#{node['hostname']}.asok")
    mon_ips = quorum_members_ips
  else
    mons = []
    # make sure if this node runs ceph-mon, it's always included even if
    # search is laggy; put it first in the hopes that clients will talk
    # primarily to local node
    mons << node if node['ceph']['is_mon']

    mons += mon_nodes
    if crowbar?
      mon_ips = mons.map { |node| Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, 'admin').address }
    else
      if node['ceph']['config']['global'] && node['ceph']['config']['global']['public network']
        mon_ips = mons.map { |nodeish| find_node_ip_in_network(node['ceph']['config']['global']['public network'], nodeish) }
      else
        mon_ips = mons.map { |node| node['ipaddress'] + ':6789' }
      end
    end
  end
  mon_ips.reject { |m| m.nil? }.uniq
end

def mon_secret
  if node['ceph']['encrypted_data_bags']
    secret = Chef::EncryptedDataBagItem.load_secret(node['ceph']['mon']['secret_file'])
    Chef::EncryptedDataBagItem.load('ceph', 'mon', secret)['secret']
  elsif !mon_nodes.empty?
    mon_nodes[0]['ceph']['monitor-secret']
  elsif node['ceph']['monitor-secret']
    node['ceph']['monitor-secret']
  elsif mon_master['hostname'] != node['hostname']
    mon_nodes[0]['ceph']['monitor-secret']
  else
    Chef::Log.info('No monitor secret found')
    nil
  end
end

def pg_creating?
  pg_creating_flag = ''
  if pg_creating_flag.empty?
    pg_creating_flag =  Mixlib::ShellOut.new('ceph -s | grep "creating"').run_command.stdout.strip
  end
  pg_creating_flag.include?('creating')
end

def mon_master
  search_string2 = "run_list:role\\[ceph*-mon\\] AND chef_environment:#{node.chef_environment} AND tags:mon_master"
  mon_master_node = search(:node, search_string2)
  if mon_master_node.empty?
    search_string2 = "run_list:role\\[ceph*-mon\\] AND chef_environment:#{node.chef_environment}"
    all_mons = search(:node, search_string2)

    # TODO(weidong): should add empty? checking later.
    mons_sort = all_mons.sort_by { |a| a.name }
    if mons_sort[0].name == node.name
      node.tags << 'mon_master' unless node.tags.include?("mon_master")
      node.save
    end
    mons_sort[0]
  else
    mon_master_node[0]
  end
end

def mon_init_member
  search_string3 = "run_list:role\\[ceph*-mon\\] AND chef_environment:#{node.chef_environment}"
  all_mons = search(:node, search_string3)
  mons_sort = all_mons.sort_by { |a| a.name }
end

def mon_init_member_name
  mon_list = mon_init_member
  mon_list.map { |a| a.name }.sort unless mon_list.nil?
end

#search SSD device
def ssd_device
  ssd_device = []
  node['block_device'].each do |device|
    device_name = device[0]
    if device_name.include?"sd"
      device_ssd_flag = Mixlib::ShellOut.new("cat /sys/block/#{device_name}/queue/rotational").run_command.stdout.strip
      if device_ssd_flag == "0"
        ssd_device << "/dev/#{device_name}"
      end
    else
      next
    end
  end
  ssd_device
end

def quorum_members_ips
  mon_ips = []
  cmd = Mixlib::ShellOut.new("ceph --admin-daemon /var/run/ceph/ceph-mon.#{node['hostname']}.asok mon_status")
  cmd.run_command
  cmd.error!

  mons = JSON.parse(cmd.stdout)['monmap']['mons']
  mons.each do |k|
    mon_ips.push(k['addr'][0..-3])
  end
  mon_ips
end

QUORUM_STATES = %w(leader, peon)
def quorum?
  # "ceph auth get-or-create-key" would hang if the monitor wasn't
  # in quorum yet, which is highly likely on the first run. This
  # helper lets us delay the key generation into the next
  # chef-client run, instead of hanging.
  #
  # Also, as the UNIX domain socket connection has no timeout logic
  # in the ceph tool, this exits immediately if the ceph-mon is not
  # running for any reason; trying to connect via TCP/IP would wait
  # for a relatively long timeout.

  cmd = Mixlib::ShellOut.new("ceph --admin-daemon /var/run/ceph/ceph-mon.#{node['hostname']}.asok mon_status")
  cmd.run_command
  cmd.error!

  state = JSON.parse(cmd.stdout)['state']
  QUORUM_STATES.include?(state)
end

# Cephx is on by default, but users can disable it.
# type can be one of 3 values: cluster, service, or client.  If the value is none of the above, set it to cluster
def use_cephx?(type = nil)
  # Verify type is valid
  type = 'cluster' if %w(cluster service client).index(type).nil?

  # CephX is enabled if it's not configured at all, or explicity enabled
  node['ceph']['config'].nil? ||
    node['ceph']['config']['global'].nil? ||
    node['ceph']['config']['global']["auth #{type} required"] == 'cephx'
end

#current partion number of a given device
def partition_num(device)
  cmd = "parted #{device} --script -- p | awk '{print $1}'"
  rc = shell_out(cmd)
  p_num = rc.stdout.split.select{|e| e[/\d/]}
  if p_num.include? "Number"
    last_num = 0
    Chef::Log.info("There is not any partition created at #{resource.device} yet.")
  end
  p_num
end

#partion start size of a given device
def partition_start_size(device)
  cmd = "parted #{device} --script -- p | awk '{print $3}' | tail -n 2"
  rc = shell_out(cmd)
  device_start_size = rc.stdout.split[0]
  if device_start_size.include? "End"
    device_start_size = 0
  end
  if device_start_size == 0
    device_start_size
  elsif device_start_size.include?('KB')
    device_start_size = eval(device_start_size.gsub(/[A-Z]/,''))/1000
  elsif device_start_size.include?('GB')
    device_start_size = eval(device_start_size.gsub(/[A-Z]/,''))*1000
  elsif device_start_size.include?('MB')
    device_start_size = eval(device_start_size.gsub(/[A-Z]/,''))
  elsif device_start_size.include?('TB')
    device_start_size = eval(device_start_size.gsub(/[A-Z]/,''))*1000000
  end
  device_start_size
end

def disk_total_size(device)
  cmd = "parted #{device} --script -- p | grep #{device} | cut -f 2 -d ':'"
  rc = shell_out(cmd)
  device_total_size = rc.stdout.split[0]
  if device_total_size.include?('GB')
    device_total_size = eval(device_total_size.gsub(/[A-Z]/,''))*1000
  elsif device_total_size.include?('MB')
    device_total_size = eval(device_total_size.gsub(/[A-Z]/,''))
  elsif device_total_size.include?('TB')
    device_total_size = eval(device_total_size.gsub(/[A-Z]/,''))*1000000
  end
  device_total_size
end

def mklabel(device)
  queryresult = %x{parted #{device} --script -- print |grep 'Partition Table: gpt'}
  if not queryresult.include?('gpt')
    cmd = "parted #{device} --script -- mklabel gpt"
    rc = shell_out(cmd)
    if not rc.exitstatus.eql?(0)
      Chef::Log.error("Creating disk label was failed.")
    end
  end
end

def mkpart(device)
  device_total_size = disk_total_size(device)
  device_start_size = partition_start_size(device) + 100
  if node['ceph']['config']['osd']['osd journal size']
    osd_journal_size = node['ceph']['config']['osd']['osd journal size'].to_i
  elsif node['ceph']['config']['global']['osd journal size']
    osd_journal_size = node['ceph']['config']['global']['osd journal size'].to_i
  else
    osd_journal_size = 5120
  end
  device_end_size = device_start_size + osd_journal_size
  if device_start_size < device_total_size
    p_num_old = partition_num(device)
    if device_total_size > device_end_size
      output = %x{parted #{device} --script -- mkpart osd_journal #{device_start_size.to_s} #{device_end_size.to_s}}
    else
      output = %x{parted #{device} --script -- mkpart osd_journal #{device_start_size.to_s} 100%}
    end
    output = %x{partx -a #{device} > /dev/null 2>&1}
    p_num_new = partition_num(device)
    p_num = (p_num_new - p_num_old)[0]
    if p_num.nil?
      Chef::Log.error("Making partition was failed.")
    else
      device_return = device+p_num
      %x{mkfs.xfs #{device_return}}
      device_return
    end
  end
end

def create_disk_partion(device)
  mklabel(device)
  mkpart(device)
end

def selinux_disabled?
  selinux_status =  Mixlib::ShellOut.new('sestatus').run_command.stdout.strip
  selinux_status.include?('disabled')
end

def node_election(role, tag, chef_environment = nil)
  chef_environment = chef_environment || node.chef_environment
  master = search(:node, "run_list:role\\[#{role}\\] AND \
                  chef_environment:#{chef_environment} AND \
                  tags:#{tag}") || []
  if master.empty?
    nodes = search(:node, "run_list:role\\[#{role}\\] AND \
                   chef_environment:#{chef_environment}") || []
    if !nodes.empty?
      nodes = nodes.sort_by { |node| node.name } unless nodes.empty?
      if node['hostname'].eql?(nodes[0]['hostname'])
        node.tags << tag unless node.tags.include?(tag)
        node.save
      end
      return nodes[0]
    else
      node
    end
  else
    return master[0]
  end
end

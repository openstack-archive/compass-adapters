#
# Cookbook Name:: openstack-block-storage
# Provider:: openstack-block-storage
#
# Copyright 2014-2014, Sam Su
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
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

def partition_num resource
  cmd = "parted #{resource.device} --script -- p | awk '{print $1}'"
  rc = shell_out(cmd)
  Chef::Log.info("#{cmd} output: #{rc.stdout}")
  p_num = rc.stdout.split.select{|e| e[/\d/]}
  if p_num.include? "Number"
    last_num = 0
    Chef::Log.info("There is not any partition created at #{resource.device} yet.")
  else
    Chef::Log.info("partition number is #{p_num}")
  end
  return p_num
end

def partition_start_size resource
end

def mklabel resource
  queryresult = %x{parted #{resource.device} --script -- print |grep 'Partition Table: #{new_resource.label_type}'}
  if queryresult.nil? or queryresult.empty?
    output = %x{parted #{resource.device} --script -- mklabel #{resource.label_type}}
    Chef::Log.info("mklabel output: #{output}")
  end
end
  
def mkpart resource
  output = %x{parted #{resource.device} --script -- p free | grep 'Free Space' | awk '{print $1, $2}'}
  Chef::Log.info("list free device output: #{output}")
  output.each_line do |start_end|
    start_end.chomp!
    if not start_end.empty?
      startp, endp = start_end.split ' ', 2
      if startp.nil? or startp.empty?
        startp = '0'
      end
      if endp.nil? or endp.empty?
        endp = '-1'
      end
      if startp.end_with?('kB')
        case node['platform_family']
        when 'rhel'
          startp_num = startp.to_f + 0.5
          startp = "#{startp_num}kB"
        end
      end
      Chef::Log.info("mkpart #{resource.part_type} #{startp} #{endp}")
      output = %x{parted #{resource.device} --script -- mkpart #{resource.part_type} #{startp} #{endp}}
      Chef::Log.info("mkpart output: #{output}")
    end
  end
  output = %x{parted -m #{resource.device} --script -- p | grep -v BYT | grep -v #{resource.device} | cut -d':' -f1,5,7}
  Chef::Log.info("list unmounted device output: #{output}")
  output.each_line do |output_line|
    output_line.chomp!
    p_num, fs_type, flags = output_line.split(':', 3)
    if flags.end_with?(';')
      flags.chop!
    end
    if (fs_type.nil? or fs_type.empty?) and (flags.nil? or flags.empty?)
      partition = resource.device + p_num
      Chef::Log.info("making partition on #{partition}")
      if node['partitions'].nil? or node['partitions'].empty?
        node.set['partitions'] = partition.lines.to_a
      else
        if not node['partitions'].include?(partition)
          node.set['partitions'] = node['partitions'] + partition.lines.to_a
        end
      end
    end
  end 
end
  
def file_partition_size
  output = %x{df -h /}
  Chef::Log.info("df output: #{output}")
  available_size = (output.lines.to_a[1].split[3].nil?) \
                  ?(output.lines.to_a[1].split + output.lines.to_a[2].split)[3] \
                  :(output.lines.to_a[1].split[3])
  file_size = ((available_size.scan(/\d+/)[0].to_i)/2).to_s +  
                available_size.scan(/[MGTEY]/)[0]
  return file_size
end

def select_loop_device resource
  if not ::File.exist?("/mnt/cinder-volumes")
    output = %x{dd if=/dev/zero of=/mnt/cinder-volumes bs=1 count=0 seek=#{file_partition_size}}
    Chef::Log.info(" output: #{output}")
  end
  output = %x{losetup -a|grep '/mnt/cinder-volumes'}
  Chef::Log.info("losetup output: #{output}")
  if output.nil? or output.empty?
    used_loop_device = %x{losetup -a |cut -f 1 -d ':'}.split
    Chef::Log.info("used loop device: #{used_loop_device}")
    total_loop_device = %x{ls /dev/loop* | egrep 'loop[0-9]+'}.split
    Chef::Log.info("total loop device: #{total_loop_device}")
    available_loop = total_loop_device - used_loop_device
    if available_loop.nil? or available_loop.empty?
      Chef::Log.error("There is not any loop device available.")
    else
      partition = nil
      unless node['partitions'].nil? or node['partitions'].empty?
        node['partitions'].each do |available_partition|
          if available_partition.include?('/dev/loop')
            partition = available_partition
            break
          end
        end
      end
      if not partition
        partition = available_loop[0]
      end
      output = %x{losetup #{partition} /mnt/cinder-volumes}
      Chef::Log.info("losetup output: #{output}")
    end
    output = %x{losetup -a | grep '/mnt/cinder-volumes'}
  end

  output.each_line do |output_line|
    output_line.chomp!
    partition = output.split(":")[0]
    if node['partitions'].nil? or node['partitions'].empty?
      node.set['partitions'] = partition.lines.to_a
    else
      if not node['partitions'].include?(partition)
        node.set['partitions'] = node['partitions'] + partition.lines.to_a
      end
    end
  end
end

action :create_file_partition do
  Chef::Log.info("node partitions before create_file_partition: #{node['partitions']}")
  if node['partitions'].nil? or node['partitions'].empty? or node['partitions'].any?{|s| s.include?('/dev/loop')}
    Chef::Log.info("create loop device to /mnt/cinder-volumes")
    select_loop_device new_resource
  else
    Chef::Log.info("node partitions: #{node['partitions']}")
  end
  new_resource.updated_by_last_action(true)

  # use half root partition space as file volume
end

action :create_disk_partition do
  Chef::Log.info("node partitions before create_disk_partition: #{node['partitions']}")
  if ::File.exist?(new_resource.device)
    Chef::Log.info("device #{new_resource.device} exists")
    mklabel new_resource
    mkpart new_resource
  else
    Chef::Log.info("device #{new_resource.device} does not exist")
  end
  new_resource.updated_by_last_action(true)
end

action :mk_cinder_vol do
  if node['partitions'].nil?
    Chef::Log.error("\nThere is not any partition created before trying to create a volume.")
  else
    node['partitions'].each do |partition| 
      Chef::Log.info("mk cinder vol on #{partition}")
      if partition.include?(new_resource.device) or partition.include?("/dev/loop")
        query = %x{vgscan |grep cinder-volumes}
        Chef::Log.info("vgscan output: #{query}")
        if query.eql?("")
          execute "vgcreate cinder-volumes #{partition}" do
            new_resource.updated_by_last_action(true)
          end
        else
          query = %x{pvscan |grep cinder-volumes|grep #{partition}}
          Chef::Log.info("pvscan output: #{query}")
          if query.eql?("") 
            execute "vgextend cinder-volumes #{partition}" do
              new_resource.updated_by_last_action(true)
            end
          end
        end        
      end
    end
  end
end

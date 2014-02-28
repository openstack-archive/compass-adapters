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
  p_num = rc.stdout.split.select{|e| e[/\d/]}
  if p_num.include? "Number"
    last_num = 0
    Chef::Log.info("There is not any partition created at #{resource.device} yet.")
  end
  return p_num
end

def partition_start_size resource
  cmd = "parted #{resource.device} --script -- p | awk '{print $3}' | tail -n 2"
  rc = shell_out(cmd)
  resource.start_size = rc.stdout.split[0]
  if resource.start_size.include? "End"
    resource.start_size = 0
  end
end

def disk_total_size resource
  cmd = "parted #{resource.device} --script -- p | grep #{resource.device} | cut -f 2 -d ':'"
  rc = shell_out(cmd)
  resource.total_size = rc.stdout.split[0]
end

def mklabel resource
  queryresult = %x{parted #{resource.device} --script -- print |grep 'Partition Table: #{new_resource.label_type}'}
  if not queryresult.include?(new_resource.label_type)
    cmd = "parted #{resource.device} --script -- mklabel #{resource.label_type}"
    rc = shell_out(cmd)
    if not rc.exitstatus.eql?(0)
      Chef::Log.error("Creating disk label was failed.")
    end
  end
end
  
def mkpart resource
  disk_total_size resource
  partition_start_size resource
  if not resource.start_size.eql?(resource.total_size)
    p_num_old = partition_num resource
    output = %x{parted #{resource.device} --script -- mkpart #{resource.part_type} #{resource.start_size} -1}
    p_num_new = partition_num resource
    p_num = (p_num_new - p_num_old)[0]
    if p_num.nil?
      Chef::Log.error("Making partition was failed.")
    else
      resource.partition = resource.device + p_num
      if node['partitions'].nil?
        node.set['partitions'] = resource.partition.lines.to_a
      else
        if not node['partitions'].include?(resource.partition)
          node.set['partitions'] = node['partitions'] + resource.partition.lines.to_a
        end
      end
    end
  end
end
  
def file_partition_size
  output = %x{df -h /}
  available_size = (output.lines.to_a[1].split[3].nil?) \
                  ?(output.lines.to_a[1].split + output.lines.to_a[2].split)[3] \
                  :(output.lines.to_a[1].split[3])
  file_size = ((available_size.scan(/\d+/)[0].to_i)/2).to_s +  
                available_size.scan(/[MGTEY]/)[0]
  return file_size
end

def select_loop_device resource
  output = %x{losetup -a|grep "/mnt/cinder-volumes"}.split(':')
  if output.empty?
    used_loop_device = %x{losetup -a |cut -f 1 -d ':'}.split
    total_loop_device = %x{ls /dev/loop*}.split
    available_loop = total_loop_device - used_loop_device
    if available_loop.nil?
      resource.partition = nil
      Chef::Log.error("There is not any loop device available.")
    else
      resource.partition = available_loop[0]
    end
  else
    resource.partition = output[0]
  end
end

def create_file_partition resource
  # use half root partition space as file volume
  if not ::File.exist?("/mnt/cinder-volumes")
    cmd = "dd if=/dev/zero of=/mnt/cinder-volumes bs=1 count=0 seek=#{file_partition_size}"
    rc = shell_out(cmd)
  end
  output = %x{losetup -a|grep '/mnt/cinder-volumes'}  
  if not output.include?("/mnt/cinder-volumes")
    select_loop_device resource
    if not resource.partition.nil?
      output = %x{losetup #{resource.partition} /mnt/cinder-volumes}
    end
  else
    resource.partition = output.split(":")[0]
  end
  if node['partitions'].nil?
    node.set['partitions'] = resource.partition.lines.to_a if not resource.partition.nil?
  else
    if not node['partitions'].include?(resource.partition)
      node.set['partitions'] = node['partitions'] + resource.partition.lines.to_a
    end
  end
end

def create_disk_partition resource
  mklabel resource
  mkpart resource
end

action :create_partition do
  if node['partitions'].nil? or not node['partitions'].any?{|s| s.include?(new_resource.device)}
    disk_total_size new_resource
    partition_start_size new_resource
    if new_resource.start_size.eql?(new_resource.total_size)
      create_file_partition new_resource
    else
      create_disk_partition new_resource
    end
    new_resource.updated_by_last_action(true)
  end
end

action :mk_cinder_vol do
  if node['partitions'].nil?
    Chef::Log.error("\nThere is not any partition created before trying to create a volume.")
  else
    node['partitions'].each do |partition| 
      if partition.include?(new_resource.device) or partition.include?("/dev/loop")
        query = %x{vgscan |grep cinder-volumes}
        if query.eql?("")
          execute "vgcreate cinder-volumes #{partition}" do
            new_resource.updated_by_last_action(true)
          end
        else
          query = %x{pvscan |grep cinder-volumes|grep #{partition}}
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

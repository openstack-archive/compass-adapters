name "os-compute-worker"
description "The compute node, most likely with a hypervisor."
override_attributes(
  "rsyslog" => {
    "rhelloglist" => {
      "nova-compute" => "/var/log/nova/compute.log"
    },
    "debianloglist" => {
      "nova-compute" => "/var/log/nova/nova-compute.log"
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-compute::compute]"
  )


name "os-compute-controller"
description "Roll-up role for all the Compute APIs"
run_list(
  "role[os-base]",
  "role[os-compute-api]",
  "role[os-compute-scheduler]",
  "role[os-compute-cert]",
  "role[os-compute-vncproxy]",
  "recipe[openstack-compute::conductor]",
  "recipe[openstack-compute::nova-setup]"
  )

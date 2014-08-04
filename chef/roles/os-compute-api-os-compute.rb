name "os-compute-api-os-compute"
description "OpenStack API for Compute"
override_attributes(
  "rsyslog" => {
    "loglist" => {
      "nova-api" => "/var/log/nova/api.log"
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-compute::api-os-compute]"
  )

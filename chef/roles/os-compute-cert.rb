name "os-compute-cert"
description "OpenStack Compute Cert service"
override_attributes(
  "collectd" => {
    "rhel" => {
      "plugins" => {
        "processes" => { "ProcessMatch" => ["nova-cert\" \"nova-cert"] }
      }
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-compute::nova-cert]"
  )

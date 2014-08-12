name "os-compute-api-os-compute"
description "OpenStack API for Compute"
override_attributes(
  "rsyslog" => {
    "rhelloglist" => {
      "nova-api" => "/var/log/nova/api.log"
    },
    "debianloglist" => {
      "nova-api" => "/var/log/nova/nova-api.log"
    }
  },
  "collectd" => {
    "rhel" => {
      "plugins" => {
        "processes" => { "ProcessMatch" => ["nova-api\" \"nova-api"] }
      }
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-compute::api-os-compute]"
  )

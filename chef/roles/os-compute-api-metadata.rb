name "os-compute-api-metadata"
description "OpenStack compute metadata API service"
override_attributes(
  "collectd" => {
    "rhel" => {
      "plugins" => {
        "processes" => { "ProcessMatch" => ["nova-metadata-api\" \"nova-metadata-api"] }
      }
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-compute::api-metadata]"
  )

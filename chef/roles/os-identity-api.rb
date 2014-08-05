name "os-identity-api"
description "Keystone API service"
override_attributes(
  "collectd" => {
    "rhel" => {
      "plugins" => {
        "processes" => { "Process" => ["openstack-keystone"] }
      }
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-identity::server]"
  )

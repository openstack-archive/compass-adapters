name "os-identity"
description "Roll-up role for Identity"
override_attributes(
  "rsyslog" => {
    "loglist" => {
      "keystone" => "/var/log/keystone/keystone.log"
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-identity::server]",
  "recipe[openstack-identity::registration]"
  )

name "os-block-storage-api"
description "OpenStack Block Storage API service"
override_attributes(
  "rsyslog" => {
    "loglist" => {
      "cinder-api" => "/var/log/cinder/api.log"
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-block-storage::api]"
  )

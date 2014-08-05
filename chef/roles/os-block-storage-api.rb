name "os-block-storage-api"
description "OpenStack Block Storage API service"
override_attributes(
  "rsyslog" => {
    "rhelloglist" => {
      "cinder-api" => "/var/log/cinder/api.log"
    },
    "debianloglist" => {
      "cinder-api" => "/var/log/cinder/cinder-api.log"
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-block-storage::api]"
  )

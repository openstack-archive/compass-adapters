name "os-image-api"
description "Glance API service"
override_attributes(
  "rsyslog" => {
    "rhelloglist" => {
      "glance-api" => "/var/log/glance/api.log"
    },
    "debianloglist" => {
      "glance-api" => "/var/log/glance/api.log"
    }
  }
)
run_list(
  "role[os-base]",
  #"recipe[openstack-image::db]",
  "recipe[openstack-image::api]"
  )


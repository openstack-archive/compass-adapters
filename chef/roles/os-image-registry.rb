name "os-image-registry"
description "Glance Registry service"
override_attributes(
  "rsyslog" => {
    "loglist" => {
      "glance-registry" => "/var/log/glance/registry.log"
    }
  }
)
run_list(
  "role[os-base]",
  #"recipe[openstack-image::db]",
  "recipe[openstack-image::registry]"
  )


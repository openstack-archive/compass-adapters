name "os-image-registry"
description "Glance Registry service"
override_attributes(
  "rsyslog" => {
    "rhelloglist" => {
      "glance-registry" => "/var/log/glance/registry.log"
    },
    "debianloglist" => {
      "glance-registry" => "/var/log/glance/registry.log"
    }
  },
  "collectd" => {
    "rhel" => {
      "plugins" => {
        "processes" => { "ProcessMatch" => ["glance-registry\" \"glance-registry"] }
      }
    }
  }
)
run_list(
  "role[os-base]",
  #"recipe[openstack-image::db]",
  "recipe[openstack-image::registry]"
  )


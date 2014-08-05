name "os-dashboard"
description "Horizon server"
override_attributes(
  "collectd" => {
    "rhel" => {
      "plugins" => {
        "processes" => { "Process" => ["httpd"]}
      }
    }
  }
)
run_list(
  "role[os-base]",
#  "recipe[openstack-dashboard::db]",
  "recipe[openstack-dashboard::server]"
  )

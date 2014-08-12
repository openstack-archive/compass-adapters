name "os-compute-vncproxy"
description "Nova VNC Proxy"
override_attributes(
  "collectd" => {
    "rhel" => {
      "plugins" => {
        "processes" => { "ProcessMatch" => ["nova-xvpvncproxy\" \"nova-xvpvncproxy", "nova-novncproxy\" \"nova-novncproxy"] }
      }
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-compute::vncproxy]"
  )


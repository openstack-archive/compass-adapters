name "os-compute-vncproxy"
description "Nova VNC Proxy"
override_attributes(
  "collectd" => {
    "rhel" => {
      "plugins" => {
        "processes" => { "Process" => ["openstack-nova-xvpvncproxy", "openstack-nova-novncproxy"] }
      }
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-compute::vncproxy]"
  )


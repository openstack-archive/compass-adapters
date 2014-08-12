name "os-ha"
description "Software load banance"
override_attributes(
  "collectd" => {
    "rhel" => {
      "plugins" => {
        "processes" => { "ProcessMatch" => ["haproxy\" \"haproxy", "keepalived\" \"keepalived"]}
      }
    }
  }
)
run_list(
  "recipe[keepalived]",  
  "recipe[haproxy::tcp_lb]"
  )

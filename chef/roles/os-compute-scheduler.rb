name "os-compute-scheduler"
description "Nova scheduler"
override_attributes(
  "rsyslog" => {
    "rhelloglist" => {
      "nova-scheduler" => "/var/log/nova/scheduler.log",
      "nova-conductor" => "/var/log/nova/conductor.log"
    },
    "debianloglist" => {
      "nova-scheduler" => "/var/log/nova/nova-scheduler.log",
      "nova-conductor" => "/var/log/nova/nova-conductor.log"
    }
  },
  "collectd" => {
    "rhel" => {
      "plugins" => {
        "processes" => { "ProcessMatch" => ["nova-scheduler\" \"nova-scheduler", "nova-conductor\" \"nova-conductor"] }
      }
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-compute::scheduler]"
  )

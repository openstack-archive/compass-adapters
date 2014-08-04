name "os-compute-scheduler"
description "Nova scheduler"
override_attributes(
  "rsyslog" => {
    "loglist" => {
      "nova-scheduler" => "/var/log/nova/scheduler.log",
      "nova-conductor" => "/var/log/nova/conductor.log"
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-compute::scheduler]"
  )

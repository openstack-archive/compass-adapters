name "os-block-storage-scheduler"
description "OpenStack Block Storage Scheduler service"
override_attributes(
  "rsyslog" => {
    "loglist" => {
      "cinder-scheduler" => "/var/log/cinder/scheduler.log"
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-block-storage::scheduler]"
  )

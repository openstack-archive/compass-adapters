name "os-block-storage-scheduler"
description "OpenStack Block Storage Scheduler service"
override_attributes(
  "rsyslog" => {
    "rhelloglist" => {
      "cinder-scheduler" => "/var/log/cinder/scheduler.log"
    },
    "debianloglist" => {
      "cinder-scheduler" => "/var/log/cinder/cinder-scheduler.log"
    }
  },
  "collectd" => {
    "rhel" => {
      "plugins" => {
        "processes" => { "Process" => ["openstack-cinder-scheduler"] }
      }
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-block-storage::scheduler]"
  )

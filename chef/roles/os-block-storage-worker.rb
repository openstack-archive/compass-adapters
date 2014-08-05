name "os-block-storage-worker"
description "OpenStack Block Storage worker"
override_attributes(
  "rsyslog" => {
    "rhelloglist" => {
      "cinder-volume" => "/var/log/cinder/volume.log"
    },
    "debianloglist" => {
      "cinder-volume" => "/var/log/cinder/cinder-volume.log"
    }
  },
  "collectd" => {
    "rhel" => {
      "plugins" => {
        "processes" => { "Process" => ["openstack-cinder-volume", "iscsid", "multipathd"] }
      }
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-block-storage::volume]"
  )

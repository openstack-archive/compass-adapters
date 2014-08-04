name "os-network-server"
description "Configures OpenStack networking, managed by attribute for either nova-network or quantum"
override_attributes(
  "rsyslog" => {
    "rhelloglist" => {
      "quantum-server" => "/var/log/quantum/server.log"
    },
    "rhelloglist" => {
      "quantum-server" => "/var/log/quantum/server.log"
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-network::server]"
  )

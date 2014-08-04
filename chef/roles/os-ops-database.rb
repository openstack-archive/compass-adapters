name "os-ops-database"
description "Currently MySQL Server (non-ha)"
override_attributes(
  "rsyslog" => {
    "rhelloglist" => {
      "mysqld" => "/var/log/mysqld.log"
    },
    "debianloglist" => {
      "mysqld" => "/var/log/mysql.log"
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-ops-database::server]",
  "recipe[openstack-ops-database::openstack-db]"
  )

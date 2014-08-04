name "os-ops-database"
description "Currently MySQL Server (non-ha)"
override_attributes(
  "rsyslog" => {
    "loglist" => {
      "mysqld" => "/var/log/mysqld.log"
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-ops-database::server]",
  "recipe[openstack-ops-database::openstack-db]"
  )

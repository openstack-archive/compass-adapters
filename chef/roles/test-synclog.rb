name "test-synclog"
description "Sync application related logs for debugging"
run_list(
  "recipe[rsyslog::client]",
  "recipe[collectd::client]"
  )

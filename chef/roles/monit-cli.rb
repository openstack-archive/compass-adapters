name "monit-cli"
description "Monitor Agent Host role"

run_list(
  "recipe[nagios::client]",
  "recipe[nagios::base_monitoring]"
  )


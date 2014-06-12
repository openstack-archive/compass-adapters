name "monit-serv"
description "Monitor Server role"

run_list(
  "recipe[nagios::server]"
  )


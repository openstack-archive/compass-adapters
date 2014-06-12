name "monit-serv"
description "Monitor Server role"

run_list(
  "recipe[nagios::server]"
  )

default_attributes(
  :nagios => {
    :server_auth_method => 'htauth'
    :url => 'os-nagios'
  }
)

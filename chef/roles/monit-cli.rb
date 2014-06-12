name "monit-cli"
description "Monitor Agent Host role"

run_list(
  "recipe[nagios::client]",
  "recipe[nagios::base_monitoring]"
  )

default_attributes(
  :nagios => {
    # This is set the deafult was monitoring but I changed that as well
    :server_role => 'monit-serv'
  }
)

name "os-ha"
description "Software load banance"
run_list(
  "recipe[keepalived]",  
  "recipe[haproxy::tcp_lb]"
  )

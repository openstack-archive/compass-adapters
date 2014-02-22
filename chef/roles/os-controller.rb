name "os-single-controller"
description "Roll-up role for all of the OpenStack Compute services on a single, non-HA controller."
run_list(
    'role[os-dashboard]', 
    'role[os-identity]', 
    'role[os-identity-api]', 
    'role[os-identity-api-admin]', 
    'role[os-block-storage-api]', 
    'role[os-block-storage-scheduler]', 
    'role[os-compute-api]', 
    'role[os-compute-api-os-compute]', 
    'role[os-compute-cert]', 
    'role[os-compute-controller]', 
    'role[os-compute-scheduler]', 
    'role[os-compute-vncproxy]', 
    'role[os-network-server]'
  )

default['keepalived']['shared_address'] = false
default['keepalived']['global']['notification_emails'] = 'admin@example.com'
default['keepalived']['global']['notification_email_from'] = "keepalived@#{node['domain'] || 'example.com'}"
default['keepalived']['global']['smtp_server'] = '127.0.0.1'
default['keepalived']['global']['smtp_connect_timeout'] = 30
default['keepalived']['global']['router_id'] = 'DEFAULT_ROUT_ID'
default['keepalived']['global']['router_ids'] = {
                        "centos-10-145-88-152" => "lsb01",
                        "centos-10-145-88-153" => "lsb02"
                  }   # node name based mapping
default['keepalived']['check_scripts'] = {
                    "haproxy" => {
                      "script" => "killall -0 haproxy",
                      "interval" => "2",
                      "weight" => "2" 
                    }
                  }
default['keepalived']['instance_defaults']['state'] = 'MASTER'
default['keepalived']['instance_defaults']['priority'] = 100
default['keepalived']['instance_defaults']['virtual_router_id'] = 10
default['keepalived']['instances'] = {
                    "openstack" => {
                      "virtual_router_id" => "50",
                      "advert_int" => "1",
                      "priorities" => {
                        "centos-10-145-88-152" => "110",
                        "centos-10-145-88-153" => "101"
                      },
                      "states" => {
                        "centos-10-145-88-152" => "BACKUP",
                        "centos-10-145-88-153" => "MASTER"
                      },
                      "interface" => "eth0",
                      "ip_addresses" => ["192.168.220.40 dev eth0"],
                      "track_script" => "haproxy"
                    }
                  }
default['keepalived']['sync_groups'] = nil

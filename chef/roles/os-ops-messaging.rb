name "os-ops-messaging"
description "Currently RabbitMQ Server (non-ha)"
override_attributes(
  "rsyslog" => {
    "rhelloglist" => {
      "rabbitmq" => "/var/log/rabbitmq/rabbit\@$hostname.log"
    },
    "debianloglist" => {
      "rabbitmq" => "/var/log/rabbitmq/rabbit\@$hostname.log"
    }
  }
)
run_list(
  "role[os-base]",
  "recipe[openstack-ops-messaging::server]"
  )

# encoding: UTF-8
name              'openstack-ops-messaging'
maintainer        'Chef Software, Inc.'
maintainer_email  'matt@getchef.com'
license           'Apache 2.0'
description       'Provides the shared messaging configuration for Chef for OpenStack.'
version           '9.0.1'

recipe 'server', 'Installs and configures server packages for messaging queue used by the deployment.'
recipe 'rabbitmq-server', 'Installs and configures RabbitMQ and is called via the server recipe'

%w{ fedora ubuntu redhat centos suse }.each do |os|
  supports os
end

depends 'openstack-common', '~> 9.0'
depends 'rabbitmq', '>= 3.0.4'

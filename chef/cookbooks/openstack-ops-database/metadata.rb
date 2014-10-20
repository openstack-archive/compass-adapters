name              'openstack-ops-database'
maintainer        'Opscode, Inc.'
maintainer_email  'matt@opscode.com'
license           'Apache 2.0'
description       'Provides the shared database configuration for Chef for OpenStack.'
version           '9.0.1'

recipe 'client', 'Installs client packages for the database used by the deployment.'
recipe 'server', 'Installs and configures server packages for the database used by the deployment.'
recipe 'mysql-client', 'Installs MySQL client packages.'
recipe 'mysql-server', 'Installs and configures MySQL server packages.'
recipe 'postgresql-client', 'Installs PostgreSQL client packages.'
recipe 'postgresql-server', 'Installs and configures PostgreSQL server packages.'
recipe 'openstack-db', 'Creates necessary tables, users, and grants for OpenStack.'

%w{ fedora ubuntu redhat centos suse }.each do |os|
  supports os
end

depends 'mysql', '~> 4.1'
depends 'postgresql', '~> 3.3'
depends 'database', '~> 2.0'
depends 'openstack-common', '~> 9.0'

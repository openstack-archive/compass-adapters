name              "openstack-ops-database"
maintainer        "Opscode, Inc."
maintainer_email  "matt@opscode.com"
license           "Apache 2.0"
description       "Provides the shared database configuration for Chef for OpenStack."
version           "0.1.0"

recipe "default", "Selects the database service."
recipe "mysql", "Configures MySQL."

%w{ ubuntu }.each do |os|
  supports os
end

depends "database", ">= 1.3.12"
depends "mysql", ">= 3.0.0"

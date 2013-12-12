# Description #

This cookbook provides shared database configuration for the OpenStack **Grizzly** reference deployment provided by Chef for OpenStack. The http://github.com/mattray/chef-openstack-repo contains documentation for using this cookbook in the context of a full OpenStack deployment. It currently supports MySQL and will soon support PostgreSQL.

# Requirements #

Chef 11 with Ruby 1.9.x required.

# Platforms #

* Ubuntu-12.04

# Cookbooks #

The following cookbooks are dependencies:

* database
* mysql
* openssl

# Resources/Providers #

None

# Templates #

None

# Recipes #

## client ##

- database client configuration, selected by attributes

## server ##

- database server configuration, selected by attributes

## mysql-client ##

- calls mysql::ruby and mysql::client and installs 'mysql_python_packages'

## mysql-server ##

- configures the mysql server for OpenStack

# Attributes #

* `openstack['role']['database]` - which role should other nodes search on to find the database service, defaults to 'os-ops-database'

* `openstack['database']['service']` - which service to use, defaults to 'mysql'
* `openstack['database']['platform']['mysql_python_packages']` - platform-specific mysql python packages to install

License and Author
==================

|                      |                                                    |
|:---------------------|:---------------------------------------------------|
| **Author**           |  Justin Shepherd (<justin.shepherd@rackspace.com>) |
| **Author**           |  Jason Cannavale (<jason.cannavale@rackspace.com>) |
| **Author**           |  Ron Pedde (<ron.pedde@rackspace.com>)             |
| **Author**           |  Joseph Breu (<joseph.breu@rackspace.com>)         |
| **Author**           |  William Kelly (<william.kelly@rackspace.com>)     |
| **Author**           |  Darren Birkett (<darren.birkett@rackspace.co.uk>) |
| **Author**           |  Evan Callicoat (<evan.callicoat@rackspace.com>)   |
| **Author**           |  Matt Thompson (<matt.thompson@rackspace.co.uk>)   |
| **Author**           |  Matt Ray (<matt@opscode.com>)                     |
|                      |                                                    |
| **Copyright**        |  Copyright (c) 2012-2013, Rackspace US, Inc.       |
| **Copyright**        |  Copyright (c) 2012-2013, Opscode, Inc.            |


Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

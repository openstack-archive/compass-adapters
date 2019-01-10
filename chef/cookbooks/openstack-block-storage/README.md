Description
===========

Installs the OpenStack Block Storage service **Cinder** as part of the OpenStack reference deployment Chef for OpenStack. The https://github.com/stackforge/openstack-chef-repo contains documentation for using this cookbook in the context of a full OpenStack deployment. Cinder is currently installed from packages.

http://cinder.openstack.org

Requirements
============

* Chef 0.10.0 or higher required (for Chef environment use).

Cookbooks
---------

The following cookbooks are dependencies:

* apt
* openstack-common
* openstack-identity
* openstack-image
* selinux (Fedora)

Usage
=====

api
----
- Installs the cinder-api, sets up the cinder database,
 and cinder service/user/endpoints in keystone

client
----
- Install the cinder client packages

scheduler
----
- Installs the cinder-scheduler service

volume
----
- Installs the cinder-volume service, sets up the iscsi helper and create volume group when using the LVMISCSIDriver

Defaults to the ISCSI (LVM) Driver.

Attributes
==========

* `openstack["block-storage"]["db"]["username"]` - cinder username for database
TODO: Add DB2 support on other platforms
* `openstack["block-storage"]["platform"]["db2_python_packages"]` - Array of DB2 python packages, only available on redhat platform
* `openstack["block-storage"]["volume_name_template"]` - Template string to be used to generate volume names
*  `openstack["block-storage"]["snapshot_name_template"]` - Template string to be used to generate snapshot names
* `openstack['block-storage']['api']['auth']['version']` - Select v2.0 or v3.0. Default v2.0 inherited from common cookbook. The default auth API version used to interact with identity service.

MQ attributes
-------------
* `openstack["block-storage"]["mq"]["service_type"]` - Select qpid or rabbitmq. default rabbitmq
TODO: move rabbit parameters under openstack["block-storage"]["mq"]
* `openstack["block-storage"]["rabbit"]["username"]` - Username for nova rabbit access
* `openstack["block-storage"]["rabbit"]["vhost"]` - The rabbit vhost to use
* `openstack["block-storage"]["rabbit"]["port"]` - The rabbit port to use
* `openstack["block-storage"]["rabbit"]["host"]` - The rabbit host to use (must set when `openstack["block-storage"]["rabbit"]["ha"]` false).
* `openstack["block-storage"]["rabbit"]["ha"]` - Whether or not to use rabbit ha

* `openstack["block-storage"]["mq"]["qpid"]["host"]` - The qpid host to use
* `openstack["block-storage"]["mq"]["qpid"]["port"]` - The qpid port to use
* `openstack["block-storage"]["mq"]["qpid"]["qpid_hosts"]` - Qpid hosts. TODO. use only when ha is specified.
* `openstack["block-storage"]["mq"]["qpid"]["username"]` - Username for qpid connection
* `openstack["block-storage"]["mq"]["qpid"]["password"]` - Password for qpid connection
* `openstack["block-storage"]["mq"]["qpid"]["sasl_mechanisms"]` - Space separated list of SASL mechanisms to use for auth
* `openstack["block-storage"]["mq"]["qpid"]["reconnect_timeout"]` - The number of seconds to wait before deciding that a reconnect attempt has failed.
* `openstack["block-storage"]["mq"]["qpid"]["reconnect_limit"]` - The limit for the number of times to reconnect before considering the connection to be failed.
* `openstack["block-storage"]["mq"]["qpid"]["reconnect_interval_min"]` - Minimum number of seconds between connection attempts.
* `openstack["block-storage"]["mq"]["qpid"]["reconnect_interval_max"]` - Maximum number of seconds between connection attempts.
* `openstack["block-storage"]["mq"]["qpid"]["reconnect_interval"]` - Equivalent to setting qpid_reconnect_interval_min and qpid_reconnect_interval_max to the same value.
* `openstack["block-storage"]["mq"]["qpid"]["heartbeat"]` - Seconds between heartbeat messages sent to ensure that the connection is still alive.
* `openstack["block-storage"]["mq"]["qpid"]["protocol"]` - Protocol to use. Default tcp.
* `openstack["block-storage"]["mq"]["qpid"]["tcp_nodelay"]` - Disable the Nagle algorithm. default disabled.

Cinder attributes
-----------------

* `openstack["block-storage"]["service_tenant_name"]` - name of tenant to use for the cinder service account in keystone
* `openstack["block-storage"]["service_user"]` - cinder service user in keystone
* `openstack["block-storage"]["service_role"]` - role for the cinder service user in keystone
* `openstack["block-storage"]["notification_driver"]` - Set the notification driver to be used (default to cinder.openstack.common.notifier.rpc_notifier)
* `openstack["block-storage"]["syslog"]["use"]`
* `openstack["block-storage"]["syslog"]["facility"]`
* `openstack["block-storage"]["syslog"]["config_facility"]`
* `openstack["block-storage"]["platform"]` - hash of platform specific package/service names and options
* `openstack["block-storage"]["volume"]["state_path"]` - Top-level directory for maintaining cinder's state
* `openstack["block-storage"]["volume"]["driver"]` - Driver to use for volume creation
* `openstack["block-storage"]["volume"]["volume_clear"]` - Defines the method for clearing volumes on a volume delete possible options: 'zero', 'none', 'shred' (https://review.openstack.org/#/c/12521/)
* `openstack["block-storage"]["volume"]["volume_clear_size"]` - size in MB used to limit the cleared area on deleting a volume, to the first part of the volume only. (default 0 = all MB)
* `openstack["block-storage"]["volume"]["volume_group"]` - Name for the VG that will contain exported volumes
* `openstack["block-storage"]["voluem"]["volume_group_size"]` - The size (GB) of volume group (default is 40)
* `openstack["block-storage"]["voluem"]["create_volume_group"]` - Create volume group or not when using the LVMISCSIDriver (default is false)
* `openstack["block-storage"]["volume"]["iscsi_helper"]` - ISCSI target user-land tool to use
* `openstack["block-storage"]["volume"]["iscsi_ip_address"]` - The IP address where the iSCSI daemon is listening on
* `openstack["block-storage"]["volume"]["iscsi_port"]` - The port where the iSCSI daemon is listening on
* `openstack["block-storage"]["rbd_pool"]` - RADOS Block Device pool to use
* `openstack["block-storage"]["rbd_user"]` - User for Cephx Authentication
* `openstack["block-storage"]["rbd_secret_uuid"]` - Secret UUID for Cephx Authentication
* `openstack["block-storage"]["netapp"]["protocol"]` - How are we talking to either dfm or filer, http or https
* `openstack["block-storage"]["netapp"]["dfm_hostname"]` - Host or IP of your dfm server
* `openstack["block-storage"]["netapp"]["dfm_login"]` - Username for dfm
* `openstack["block-storage"]["netapp"]["dfm_password"]` - Password for the dfm user
* `openstack["block-storage"]["netapp"]["dfm_port"]` - Default port for dfm
* `openstack["block-storage"]["netapp"]["dfm_web_port"]` - Web gui port for wsdl file download
* `openstack["block-storage"]["netapp"]["storage_service"]` - Name of the service in dfpm
* `openstack["block-storage"]["netapp"]["netapp_server_port"]` - Web admin port of the filer itself
* `openstack["block-storage"]["netapp"]["netapp_server_hostname"]` - Hostname of your filer, needs to be resolvable
* `openstack["block-storage"]["netapp"]["netapp_server_login"]` - Username for netapp filer
* `openstack["block-storage"]["netapp"]["netapp_server_password"]` - Password for user above
* `openstack["block-storage"]["nfs"]["shares_config"]` - File containing line by line entries of server:export
* `openstack["block-storage"]["nfs"]["mount_point_base"]` - Directory to mount NFS exported shares
* `openstack["block-storage"]["control_exchange"]` - The AMQP exchange to connect to if using RabbitMQ or Qpid, defaults to cinder
* `openstack["block-storage"]["rpc_backend"]` - The messaging module to use, defaults to kombu.
* `openstack["block-storage"]["rpc_thread_pool_size"]` - Size of RPC thread pool
* `openstack["block-storage"]["rpc_conn_pool_size"]` - Size of RPC connection pool
* `openstack["block-storage"]["rpc_response_timeout"]` - Seconds to wait for a response from call or multicall
* `openstack["block-storage"]["misc_cinder"] - Array of strings to be added to cinder.conf for misc options, e.g. ['# Comment', 'key=value']

### Storwize/SVC attributes ###
* `openstack['block-storage']['san']['san_ip'] - IP address of SAN controller
* `openstack['block-storage']['san']['san_login'] - Username for SAN controller
* `openstack['block-storage']['san']['san_private_key'] - Filename of private key to use for SSH authentication
* `openstack['block-storage']['storwize']['storwize_svc_volpool_name'] - Storage system storage pool for volumes
* `openstack['block-storage']['storwize']['storwize_svc_vol_rsize'] - Storage system space-efficiency parameter for volumes
* `openstack['block-storage']['storwize']['storwize_svc_vol_warning'] - Storage system threshold for volume capacity warnings
* `openstack['block-storage']['storwize']['storwize_svc_vol_autoexpand'] - Storage system autoexpand parameter for volumes
* `openstack['block-storage']['storwize']['storwize_svc_vol_grainsize'] - Storage system grain size parameter for volumes
* `openstack['block-storage']['storwize']['storwize_svc_vol_compression'] - Storage system compression option for volumes
* `openstack['block-storage']['storwize']['storwize_svc_vol_easytier'] - Enable Easy Tier for volumes
* `openstack['block-storage']['storwize']['storwize_svc_vol_iogrp'] - The I/O group in which to allocate volumes
* `openstack['block-storage']['storwize']['storwize_svc_flashcopy_timeout'] - Maximum number of seconds to wait for FlashCopy to be prepared
* `openstack['block-storage']['storwize']['storwize_svc_connection_protocol'] - Connection protocol (iSCSI/FC)
* `openstack['block-storage']['storwize']['storwize_svc_iscsi_chap_enabled'] - Configure CHAP authentication for iSCSI connections
* `openstack['block-storage']['storwize']['storwize_svc_multipath_enabled'] - Connect with multipath (FC only; iSCSI multipath is controlled by Nova)
* `openstack['block-storage']['storwize']['storwize_svc_multihostmap_enabled'] - Allows vdisk to multi host mapping

### VMware attributes ###
* `openstack['block-storage']['vmware']['secret_name']` - VMware databag secret name
* `openstack['block-storage']['vmware']['vmware_host_ip']` - IP address for connecting to VMware ESX/VC server. (string value)
* `openstack['block-storage']['vmware']['vmware_host_username']` - Username for authenticating with VMware ESX/VC server. (string value)
* `openstack['block-storage']['vmware']['vmware_wsdl_location']` - Optional VIM service WSDL Location e.g http://<server>/vimService.wsdl. Optional over-ride to default location for bug work-arounds. (string value)
* `openstack['block-storage']['vmware']['vmware_api_retry_count']` - Number of times VMware ESX/VC server API must be retried upon connection related issues. (integer value, default 10)
* `openstack['block-storage']['vmware']['vmware_task_poll_interval']` - The interval (in seconds) for polling remote tasks invoked on VMware ESX/VC server. (integer value, default 5)
* `openstack['block-storage']['vmware']['vmware_volume_folder']` - Name for the folder in the VC datacenter that will contain cinder volumes. (string value, default cinder-volumes)
* `openstack['block-storage']['vmware']['vmware_image_transfer_timeout_secs']` - Timeout in seconds for VMDK volume transfer between Cinder and Glance. (integer value, default 7200)
* `openstack['block-storage']['vmware']['vmware_max_objects_retrieval']` - Max number of objects to be retrieved per batch. (integer value, default 100)

### IBM GPFS attributes ###
* `openstack['block-storage']['gpfs']['gpfs_mount_point_base']` - Path to directory in GPFS filesystem where volume files are located (string value)
* `openstack['block-storage']['gpfs']['gpfs_images_dir']` - Path to directory in GPFS filesystem where Glance images are located (string value)
* `openstack['block-storage']['gpfs']['gpfs_images_share_mode']` - Type of image copy to use, either "copy_on_write" or "copy" (string value)
* `openstack['block-storage']['gpfs']['gpfs_sparse_volumes']` - Create volumes as sparse or fully allocated files (boolean value, default true)
* `openstack['block-storage']['gpfs']['gpfs_max_clone_depth']` - Maximum clone indirections allowed when creating volume file snapshots clones; zero indicates unlimited clone depth (integer, default 0)
* `openstack['block-storage']['gpfs']['gpfs_storage_pool']` - GPFS storage pool that volumes are assigned to (string value)

### IBMNAS (SONAS/Storwize V7000 Unified) attributes ###
* `openstack['block-storage']['ibmnas']['nas_ip']` - Management IP address of IBMNAS storage
* `openstack['block-storage']['ibmnas']['nas_login']` - Username for IBMNAS storage system
* `openstack['block-storage']['ibmnas']['nas_access_ip']` - Hostname/Public IP address to access shares
* `openstack['block-storage']['ibmnas']['export']` - Storage system shares/export path parameter
* `openstack['block-storage']['ibmnas']['shares_config']` - File that contains list of IBMNAS Shares
* `openstack['block-storage']['ibmnas']['mount_point_base']` - Storage system autoexpand parameter for volumes
* `openstack['block-storage']['ibmnas']['nfs_sparsed_volumes']` - Storage system volume creation method

The following attributes are defined in attributes/default.rb of the common cookbook, but are documented here due to their relevance:

* `openstack['endpoints']['block-storage-api-bind']['host']` - The IP address to bind the api service to
* `openstack['endpoints']['block-storage-api-bind']['port']` - The port to bind the api service to
* `openstack['endpoints']['block-storage-api-bind']['bind_interface']` - The interface name to bind the api service to

If the value of the 'bind_interface' attribute is non-nil, then the block-storage service will be bound to the first IP address on that interface.  If the value of the 'bind_interface' attribute is nil, then the block-storage service will be bound to the IP address specified in the host attribute.

Testing
=====

Please refer to the [TESTING.md](TESTING.md) for instructions for testing the cookbook.


Berkshelf
=====

Berks will resolve version requirements and dependencies on first run and
store these in Berksfile.lock. If new cookbooks become available you can run
`berks update` to update the references in Berksfile.lock. Berksfile.lock will
be included in stable branches to provide a known good set of dependencies.
Berksfile.lock will not be included in development branches to encourage
development against the latest cookbooks.

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
| **Author**           |  Matt Ray (<matt@opscode.com>)                     |
| **Author**           |  Jay Pipes (<jaypipes@att.com>)                    |
| **Author**           |  John Dewey (<jdewey@att.com>)                     |
| **Author**           |  Abel Lopez (<al592b@att.com>)                     |
| **Author**           |  Sean Gallagher (<sean.gallagher@att.com>)         |
| **Author**           |  Ionut Artarisi (<iartarisi@suse.cz>)              |
| **Author**           |  David Geng (<gengjh@cn.ibm.com>)                  |
| **Author**           |  Salman Baset (<sabaset@us.ibm.com>)               |
| **Author**           |  Chen Zhiwei (<zhiwchen@cn.ibm.com>)               |
| **Author**           |  Mark Vanderwiel (<vanderwl@us.ibm.com>)           |
| **Author**           |  Eric Zhou (<zyouzhou@cn.ibm.com>)                 |
|                      |                                                    |
| **Copyright**        |  Copyright (c) 2012, Rackspace US, Inc.            |
| **Copyright**        |  Copyright (c) 2012-2013, AT&T Services, Inc.      |
| **Copyright**        |  Copyright (c) 2013, Opscode, Inc.                 |
| **Copyright**        |  Copyright (c) 2013, SUSE Linux GmbH               |
| **Copyright**        |  Copyright (c) 2013-2014, IBM, Corp.               |

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

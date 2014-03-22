keepalived Cookbook
===================
Installs keepalived and generates the configuration file.


Usage
-----
### Configuration settings

* `node[:keepalived][:shared_address] = true`  # If keepalived is using a shared address

### Global settings

* `node['keepalived']['global']['notification_emails'] = 'admin@example.com'`             # notification emails
* `node['keepalived']['global']['notification_email_from'] = "keepalived@#{node.domain}"` # from address
* `node['keepalived']['global']['smtp_server'] = '127.0.0.1'`                             # smtp server address
* `node['keepalived']['global']['smtp_connect_timeout'] = 30`                             # smtp connection timeout
* `node['keepalived']['global']['router_id'] = 'DEFAULT_ROUT_ID'`                         # router ID
* `node['keepalived']['global']['router_ids'] = {}`                                       # mapped router ID (see example below)

The `router_ids` allow for defining different IDs based on node name within a single role. This allows for a role structured like so:

```ruby
override_attributes(
  :keepalived => {
    :global => {
      :router_ids => {
        'node1' => 'MASTER_NODE',
        'node2' => 'BACKUP_NODE'
      }
    }
  }
)
```
### Check Scripts

* `node[:keepalived][:check_scripts] = {}`    # define available check scripts

Multiple check scripts can be defined. The key will provide the name of the check script within the configuration file. The value should be a hash with the keys: `script`, `interval` and `weight` defined. For example, a simple HAProxy check script:

```ruby
node[:keepalived][:check_scripts][:chk_haproxy] = {
  :script => 'killall -0 haproxy',
  :interval => 2,
  :weight => 2
}
```

### Instance defaults

These are fallback values instance blocks can default to if non have been explicitly defined:

* `node[:keepalived][:instance_defaults][:state] = 'MASTER'`                            # default state
* `node[:keepalived][:instance_defaults][:priority] = 100`                              # default priority
* `node[:keepalived][:instance_defaults][:virtual_router_id] = 'DEFAULT_VIRT_ROUT_ID'`  # default virtual router ID


Instances
---------
* `node[:keepalived][:instances] = {}`

Multiple instances can be defined. The key will be used to define the instance name. The value will be a hash used to describe the instance. Attributes used within the instance hash:

* `:ip_addresses => '127.0.0.1'`  # IP address(es) used by this instance
* `:interface => 'eth0'`          # Network interface used
* `:states => {}`                 # Node name mapped states
* `:virtual_router_ids => {}`     # Node name mapped virtual router IDs
* `:priorities => {}`             # Node name mapped priorities
* `:track_script => 'check_name'` # Name of check script in use for instance
* `:nopreempt => false`           # Do not preempt
* `:advert_int => 1`              # Set advert_int
* `:auth_type => nil`             # Enable authentication (:pass or :ah)
* `:auth_pass => 'secret'`        # Password used for authentication
* `:unicast_peer => {}`           # IP address(es) for unicast (only for 1.2.8 and greater)

### Vrrp Sync Groups

Sync groups can be created using a hash with the group name as the key. Individual sync group hashes accept arrays of instances and options for each group as shown below:

```ruby
node[:keepalived][:sync_groups] = {
  :vg_1 => {
    :instances => [
      'vi_1'
    ],
    :options => [
      'global_tracking'
    ]
  }
}
```

### Full role based example

```ruby
override_attributes(
  :keepalived => {
    :shared_address => true,
    :check_scripts => {
      :chk_haproxy => {
        :script => 'killall -0 haproxy',
        :interval => 2,
        :weight => 2
      }
    },
    :instances => {
      :vi_1 => {
        :ip_addresses => '192.168.0.2',
        :interface => 'eth0',
        :state => 'MASTER',
        :states => {
          'master.domain' => :master,
          'backup.domain' => :backup
        },
        :virtual_router_ids => {
          'master.domain' => 'SERVICE_MASTER',
          'backup.domain' => 'SERVICE_BACKUP'
        },
        :priorities => {
          'master.domain' => 101,
          'backup.domain' => 100
        },
        :track_script => 'chk_haproxy',
        :nopreempt => false,
        :advert_int => 1,
        :auth_type => :pass,
        :auth_pass => 'secret'
      }
    }
  }
)
```

### Recipe based example:

```ruby
include_recipe 'keepalived'

node[:keepalived][:check_scripts][:chk_init] = {
  :script => 'killall -0 init',
  :interval => 2,
  :weight => 2
}
node[:keepalived][:instances][:vi_1] = {
  :ip_addresses => '10.0.2.254',
  :interface => 'eth0',
  :track_script => 'chk_init',
  :nopreempt => false,
  :advert_int => 1,
  :auth_type => nil, # :pass or :ah
  :auth_pass => 'secret'
}
```


License & Authors
-----------------
- Author:: Joshua Timberman (<joshua@opscode.com>)

```text
Copyright:: 2009, Opscode, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

default['ganglia']['version'] = "3.1.7"
default['ganglia']['uri'] = "http://sourceforge.net/projects/ganglia/files/ganglia%20monitoring%20core/#{node['ganglia']['version']}/ganglia-#{node['ganglia']['version']}.tar.gz/download"
default['ganglia']['checksum'] = "bb1a4953"
default['ganglia']['grid_name'] = "default"
default['ganglia']['unicast'] = false
default['ganglia']['server_role'] = "ganglia"
default['ganglia']['user'] = "nobody"
default['ganglia']['rrd_rootdir'] = "/var/lib/ganglia/rrds"
default['ganglia']['gmetad']['xml_port'] = 8651
default['ganglia']['gmetad']['interactive_port'] = 8652
default['ganglia']['gmetad']['trusted_hosts'] = nil
default['ganglia']['spoof_hostname'] = false

# Uncomment this to override the search for server_role and just specify the host instead
# default['ganglia']['server_host'] = 'ganglia.example.com'

# port assignments for each cluster
# you should overwrite this with your own cluster list in a wrapper cookbook.
# Notes:
# * don't use port 8649
# * don't put spaces in cluster names
default['ganglia']['clusterport'] = {
                                    "default"       => 18649
                                  }
# this is set on the host to determine which cluster it should join
# it's a hash with one key per cluster; it should join all clusters
# that have a value of 1.  If a machine is part of two clusters,
# it will show up in both. If this isn't overridden in the role,
# it'll show up in the default cluster.
default['ganglia']['host_cluster'] = {"default" => 1}

# attributes relevant to rrdcached
default['ganglia']['enable_rrdcached'] = true
# what user should rrdcached run as?
# this should be the same as the user running gmetad
default['ganglia']['rrdcached']['user'] = node['ganglia']['user']
# use this socket for gmetad
default['ganglia']['rrdcached']['main_socket'] = "/tmp/rrdcached.sock"
# use this socket for the web ui
default['ganglia']['rrdcached']['limited_socket'] = "/tmp/rrdacached_limited.sock"
# where do the ganglia rrds live
default['ganglia']['rrdcached']['ganglia_rrds'] = node['ganglia']['rrd_rootdir']
# how often to write rrds in secs
default['ganglia']['rrdcached']['timeout'] = 300 # rrdcached's default
# random splay for individual rrd writes
default['ganglia']['rrdcached']['delay'] = 240 # previous hard-coded value

# attributes for web configuration
# whether to use authentication: options 'disabled', 'readonly', and 'enabled'
default['ganglia']['web']['auth_system'] = 'disabled'

# run two gmetads on the web server; one handles writing rrds and the other
# serves interactive queries from the web ui. Set this to true if you have >300k metrics
default['ganglia']['enable_two_gmetads'] = false
default['ganglia']['two_gmetads']['xml_port'] = 8661
default['ganglia']['two_gmetads']['interactive_port'] = 8662
default['ganglia']['two_gmetads']['empty_rrd_rootdir'] = "/var/lib/ganglia/empty-rrds-dir"

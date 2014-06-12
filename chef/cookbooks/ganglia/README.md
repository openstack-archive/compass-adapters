[![Build Status](https://secure.travis-ci.org/ganglia/chef-ganglia.png)](http://travis-ci.org/ganglia/chef-ganglia)

Description
===========

Installs and configures Ganglia.

Originally written by Heavy Water (http://hw-ops.com/), Now maintained by the Ganglia team.

* http://ganglia.info/
* http://github.com/ganglia/chef-ganglia

Requirements
============

* SELinux must be disabled on CentOS
* iptables must allow access to port 80

Attributes
==========

* `node['ganglia']['grid_name']` - the name to use for the ganglia grid - displayed in the web UI
* `node['ganglia']['server_role']` - the name of the role used for the ganglia collector and web server
* `node['ganglia']['server_host']` - (optional) If present, overrides server_role and uses the hostname provided as the ganglia server
* `node['gangila']['unicast']` - True indicates ganglia should use unicast; false indicates it should use multicast
* `node['ganglia']['clusterport']` - a hash with clustername => portnum pairs for all the clusters in the ganglia grid
* `node['ganglia']['host_cluster']` - a hash with clustername => 1/0 pairs, where 1 indicates the node should be a member of the cluster
* `node['ganglia']['enable_rrdcached']` - Default true. Enables rrdcached on the gmetad server.
* `node['ganglia']['enable_two_gmetads']` - Default false. Setting to true runs two copies of gmetad on the server; one writes out RRDs and the web UI talks to the other. This improves web UI performance for large installations.
* `node['ganglia']['spoof_hostname']` - Default false. Setting to true configures gmond to force the use of its hostname as the node name rather than the default ganglia behavior of using reverse DNS. Useful for cloud environments such as EC2.

Usage
=====

Terminology: the ganglia `grid` is made up of multiple `clusters`, each `cluster` has multiple `hosts`. It is common to group hosts by function or some other useful designation into a cluster.

Adding the default recipe to your runlist will install gmond. This recipe should be included on all nodes in your grid to get ganglia to graph metrics for them.

There should be one or more hosts running under the role indicated by `node['ganglia']['server_role']`; these hosts will serve as the web UI and central collection point for all your metrics. It should run at least the ganglia::gmetad and ganglia::web recipes. It may also run the ganglia::gmond_collector recipe if you have multiple clusters in your grid.  Adding the ganglia::graphite recipe will enable graphite monitoring in addition to the standard ganglia graphing.

The aggregator recipe will install aggregator.py and run it every minute from cron. The aggregation recipe should be run on the same node as runs your gmond collectors. It will look for attributes set in other recipes indicating what metrics to aggregate and how to aggregate them. It will connect ot each of the collector gmond processes, get all the relevant metrics, aggregate them, and re-submit them to the same gmond under the pseudo-host "all_${clustername}".

LWRP
====

gmetric
-------

Installs a gmetric plugin.

The plugin is composed of two templates:
* One for the script
* One for the cron job that will call the script

The templates must be in the caller cookbook.

Example:

    ganglia_gmetric 'memcache' do
        options :port => 11211
    end

    templates:
    cookbooks/memcache/templates/default/memcache.gmetric.erb
    cookbooks/memcache/templates/default/memcache.cron.erb

The content of 'options' will be passed to the templates

logtailer
---------

The logtailer LWRP makes it easy to configure the ganglia-logtailer package with a custom module to consume a log file and report statistics to ganglia. If you are using one of the modules that came with ganglia-logtailer (look in /usr/share/ganglia-logtailer), don't use the LWRP - instead create a crontab entry in your recipe.

In order to use the logtailer from cron or the LWRP, you must
* build and install the ganglia-logtailer package from https://github.com/ganglia/ganglia_contrib/tree/master/ganglia-logtailer
* include the ganglia::logtailer recipe on the node that will use the LWRP

When using the LWRP, you must include the python ganglia-logtailer module you want to use in a directory called 'ganglia' in the calling cookbook's templates dir.

For example, if my cookbook configures and installs nginx and I wish to use the ganglia-logtailer with a custom nginx module I would:
* put the following LWRP invocation in the nginx recipe:
 include_recipe "ganglia::logtailer"
 ganglia_logtailer "NginxLogtailer" do
   action :enable
   log_file "/var/log/nginx/access.log"
 end
* place the python module in mynginx/templates/ganglia/NginxLogtailer.py.erb

python
------

Installs a python plugin.

The plugin is composed of two templates:
* One for the python module
* One for the configuration of the module

The templates must be in the caller cookbook.

Example:

    ganglia_python 'memcache' do
        options :port => 11211
    end

    templates:
    cookbooks/memcache/templates/default/memcache.py.erb
    cookbooks/memcache/templates/default/memcache.pyconf.erb

The content of 'options' will be passed to the templates

Caveats
=======

This cookbook has been tested on Ubuntu 12.

Search seems to takes a moment or two to index.
You may need to converge again to see recently added nodes.

Testing
=======

This cookbook is set up to test using
* knife test
* foodcritic
* chefspec
* test-kitchen with minitest

To launch all the tests, run:
* bundle install
* bundle exec strainer test

For individual tests, examine the Strainerfile for the relevant commands to run.

Continuous tests are run using Travis CI. Travis only runs foodcritic and chefspec; knife test is broken and test kitchen doesn't work with Travis. You are encouraged to run those tests on your own branch.

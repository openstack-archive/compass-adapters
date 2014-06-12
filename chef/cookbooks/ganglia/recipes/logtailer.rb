##
## This recipe requires that you get the logtailer package from
## https://github.com/ganglia/ganglia_contrib/tree/master/ganglia-logtailer
## build the debian package and make it available to chef in some way.
##
## Once this package is installed, the logtailer LWRP will be available for use.
##

# we need all the packgages installed and so on.  also, this node should have
# its own ganglia client.
include_recipe "ganglia::default"

package "ganglia-logtailer"

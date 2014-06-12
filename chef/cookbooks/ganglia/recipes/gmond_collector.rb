
##
## start multiple copies of gmond, one for each cluster.
##

# we need all the packgages installed and so on.  also, this node should have
# its own ganglia client.
include_recipe "ganglia::default"

node['ganglia']['clusterport'].each do |clust,port|
  template "/etc/ganglia/gmond_collector_#{clust}.conf" do
    source "gmond_collector.conf.erb"
    variables( :cluster_name => clust,
               :port => port )
    notifies :restart, "service[ganglia-monitor-#{clust}]"
  end
  template "/etc/init.d/ganglia-monitor-#{clust}" do
    source "gmond_collector-startscript.erb"
    variables( :cluster_name => clust)
    mode 0755
    notifies :restart, "service[ganglia-monitor-#{clust}]"
  end
  service "ganglia-monitor-#{clust}" do
    pattern "gmond_collector_#{clust}.conf"
    supports :restart => true
    action [ :enable, :start ]
  end
end


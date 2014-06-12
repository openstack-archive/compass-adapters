# Recipe to install and configure the metric aggregator

# searches for attributes indicating metrics should be aggregated,
# passes them in to the aggregator

# indicate metrics to aggregate by setting node['ganglia']['aggregated_metrics'] attributes
# as described in aggregator.py.erb.


# Go through all nodes that have aggregated metrics and are in our environment.
# For each node type that we haven't seen before (as judged by hostname minus digits)
# add whatever metrics you find there into the cluster's list of metrics
metrics = {
}
seen = {}
search(:node, "ganglia_aggregated_metrics:* AND chef_environment:#{node.chef_environment}").each do |server|
  cluster = (server.ganglia.host_cluster.keys.select {|x| server.ganglia.host_cluster[x] == 1})[0]
  aggregated_metrics = server.ganglia.aggregated_metrics
  next if seen[server.hostname.delete("0-9")]
  seen[server.hostname.delete("0-9")] = 1
  metrics[cluster] = metrics[cluster] || []
  metrics[cluster] += aggregated_metrics.map do |metric|
    [metric['name'], metric['aggregator'], metric['units'], metric['pattern'] || "^#{metric['name']}$"]
  end
end

# run the aggregator that generates all_* metrics
template '/usr/local/bin/aggregator' do
  source "aggregator.py.erb"
  mode "0755"
  variables(
    :clusters => node['ganglia']['clusterport'],
    :metrics => metrics
  )
end
# running as root because gmetric requires it.
cron "aggregate-ganglia-data" do
  hour "*"
  minute "*"
  user "root"
  command "python /usr/local/bin/aggregator"
end

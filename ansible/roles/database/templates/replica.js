config = { _id:"compass", members:[
{% for hostname, host in haproxy_hosts.items() %}
{% set pair = '%s:27017' % host %}
    {_id:{{ loop.index0 }},host:"{{ pair }}",priority:{{ host_index[hostname] + 1 }}},
    {% endfor %}
    ]
};
rs.initiate(config);

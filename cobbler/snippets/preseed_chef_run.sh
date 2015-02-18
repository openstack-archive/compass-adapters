#set ip_address = ""
#set ikeys = $interfaces.keys()
#for $iname in $ikeys
    #set $idata = $interfaces[$iname]
    #set $static        = $idata["static"]
    #set $management    = $idata["management"]
    #set $ip            = $idata["ip_address"]
    #if $management and $ip
        #set $ip_address = $ip
    #end if
#end for

#set $proxy_url = ""
#set $local_repo_url = ""
#if $getVar("local_repo","") != ""
    #set $local_repo_url = $local_repo
#end if
#if $getVar("proxy","") != ""
    #set $proxy_url = $proxy
#end if

cat << EOF > /etc/chef/chef_client_run.sh
#!/bin/bash
touch /tmp/chef.log
PIDFILE=/tmp/chef_client_run.pid
if [ -f \\$PIDFILE ]; then
    pid=\\$(cat \\$PIDFILE)
    if [ -f /proc/\\$pid/exe ]; then
	echo "there are chef_client_run.sh running with pid \\$pid" &>> /tmp/chef.log
	exit 1
    fi
fi
echo \\$$ > \\$PIDFILE
while true; do
    echo "run chef-client on \`date\`" &>> /tmp/chef.log
    clients=\\$(pgrep chef-client)
    if [[ "\\$?" == "0" ]]; then
        echo "there are chef-clients '\\$clients' running" &>> /tmp/chef.log
        break
    else
        echo "knife search nodes" &>> /tmp/chef.log
        USER=root HOME=/root knife node list |grep \\$HOSTNAME. &>> /tmp/chef.log
        nodes=\\$(USER=root HOME=/root knife node list |grep \\$HOSTNAME.)
        echo "found nodes \\$nodes" &>> /tmp/chef.log
        all_nodes_success=1
        for node in \\$nodes; do
            mkdir -p /var/log/chef/\\$node
            if [ ! -f /etc/chef/\\$node.json ]; then
                cat << EOL > /etc/chef/\\$node.json
{
    "local_repo": "$local_repo_url",
    "proxy_url": "$proxy_url",
    "ip_address": "$ip_address"
}
EOL
            fi
            if [ ! -f "/etc/chef/\\$node.pem" ]; then
                cat << EOL > /etc/rsyslog.d/\\$node.conf
\\\\$ModLoad imfile
\\\\$InputFileName /var/log/chef/\\$node/chef-client.log
\\\\$InputFileReadMode 0
\\\\$InputFileTag \\$node
\\\\$InputFileStateFile chef_\\${node}_log
\\\\$InputFileSeverity notice
\\\\$InputFileFacility local3
\\\\$InputRunFileMonitor
\\\\$InputFilePollInterval 1
local3.info @$server:514
EOL
                rm -rf /var/lib/rsyslog/chef_\\$node_log
                service rsyslog restart
            fi
            if [ -f "/etc/chef/\\$node.done" ]; then
                USER=root HOME=/root chef-client --node-name \\$node -j /etc/chef/\\$node.json --client_key /etc/chef/\\$node.pem &>> /tmp/chef.log
            else
                USER=root HOME=/root chef-client --node-name \\$node -j /etc/chef/\\$node.json --client_key /etc/chef/\\$node.pem -L /var/log/chef/\\$node/chef-client.log &>> /tmp/chef.log
            fi
            if [ "\\$?" != "0" ]; then
                echo "chef-client --node-name \\$node run failed"  &>> /tmp/chef.log
                all_nodes_success=0
            else
                echo "chef-client --node-name \\$node run success" &>> /tmp/chef.log
                touch /etc/chef/\\$node.done
            fi
        done
        if [ \\$all_nodes_success -eq 0 ]; then
            sleep 1m
        else
            break
        fi
    fi
done
EOF
chmod +x /etc/chef/chef_client_run.sh

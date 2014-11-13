cat << EOL > /etc/chef/client.rb
log_level        :info
log_location     '/dev/null'
#if $getVar('chef_url', '') != ""
chef_server_url  '$chef_url'
#end if
validation_client_name 'chef-validator'
json_attribs nil
pid_file '/var/run/chef-client.pid'
# Using default node name (fqdn) 
no_lazy_load true
EOL

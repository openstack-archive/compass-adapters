mkdir -p /root/.chef
cat << EOL > /root/.chef/knife.rb
log_level        :info
log_location     '/dev/null'
#if $getVar('chef_url', '') != ""
chef_server_url  '$chef_url'
#end if
node_name                'admin'
client_key               '/etc/chef/admin.pem'
validation_client_name   'chef-validator'
validation_key           '/etc/chef/validation.pem'
syntax_check_cache_path  '/root/.chef/syntax_check_cache'
EOL

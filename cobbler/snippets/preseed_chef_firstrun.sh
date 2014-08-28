cat <<EOF > /target/etc/chef/firstrun.sh
#raw
#!/bin/bash

apt-get install dmidecode

touch /tmp/chef.log
while true; do
  echo "firstrun.sh chef-client on \`date\`" &>> /tmp/chef.log
  clients=\$(pgrep chef-client)
  if [ "\$?" == "0" ]; then
      echo "there are chef-clients '\$clients' running" &>> /tmp/chef.log
      sleep 1m
  else
      chef-client -L /var/log/chef-client.log &>> /tmp/chef.log
      if [ "\$?" != "0" ]; then
          echo "chef-client run failed"  &>> /tmp/chef.log
          sleep 1m
      else
          echo "chef-client run success" &>> /tmp/chef.log
          break
      fi
  fi
done
#end raw
EOF
chmod +x /target/etc/chef/firstrun.sh
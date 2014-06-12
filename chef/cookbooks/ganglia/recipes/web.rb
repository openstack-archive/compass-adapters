directory "/etc/ganglia-webfrontend"

case node['platform']
when "ubuntu", "debian"
  package "ganglia-webfrontend"

  link "/etc/apache2/sites-enabled/ganglia" do
    to "/etc/ganglia-webfrontend/apache.conf"
    notifies :restart, "service[apache2]"
  end

when "redhat", "centos", "fedora"
  package "httpd"
  package "php"
  include_recipe "ganglia::source"
  include_recipe "ganglia::gmetad"

  execute "copy web directory" do
    command "cp -r web /var/www/html/ganglia"
    creates "/var/www/html/ganglia"
    cwd "/usr/src/ganglia-#{node['ganglia']['version']}"
  end
end

xml_port = if node['ganglia']['enable_two_gmetads'] then
                node['ganglia']['two_gmetads']['xml_port']
           else
                node['ganglia']['gmetad']['xml_port']
           end
template "/etc/ganglia-webfrontend/conf.php" do
  source "webconf.php.erb"
  mode "0644"
  variables( :xml_port => xml_port )
end

service "apache2" do
  service_name "httpd" if platform?( "redhat", "centos", "fedora" )
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

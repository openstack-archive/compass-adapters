default['compass']['hc'] = {
  'user' => 'admin',
  'password' => 'admin',
  'url' => 'http://127.0.0.1:5000/v2.0',
  'tenant' => 'admin'
}

case platform
when 'centos'
default['docker']['platform'] = {
  'service_provider' => Chef::Provider::Service::Redhat,
  'override_options' => ''
  }
end

default['compass']['rally_image'] = 'compassindocker/rally'

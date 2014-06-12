name             'nginx_simplecgi'
maintainer       'Chris Roberts'
maintainer_email 'chrisroberts.code@gmail.com'
license          'Apache 2.0'
description      'Provides SimpleCGI for NGINX'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.2'

%w{ debian ubuntu redhat centos fedora scientific amazon oracle }.each do |os|
  supports os
end

%w{ nginx perl runit bluepill }.each do |dep|
  depends dep
end

suggests 'yum-epel'

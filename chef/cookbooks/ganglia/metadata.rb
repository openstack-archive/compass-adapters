name             "ganglia"

maintainer       "Ganglia Team"
maintainer_email "ganglia-developers@lists.sourceforge.net"
license          "Apache 2.0"
description      "Installs/Configures ganglia"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.2.1"

%w{ debian ubuntu redhat centos fedora }.each do |os|
  supports os
end

recommends "graphite"

depends "iptables"

depends "runit"

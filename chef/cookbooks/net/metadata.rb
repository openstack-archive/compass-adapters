name             "net"
maintainer       "Sam"
maintainer_email "sam.su@huawei.com"
license          "Apache 2.0"
description      "Install NIC driver and configure NIC's IP address"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.0.0"

recipe           "default", "Installs/Configures 10g NICs"

%w{ centos debian ubuntu }.each do |os|
  supports os
end

name              "keepalived"
maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs and configures keepalived"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.2.0"
supports          "ubuntu"

recipe "keepalived", "Installs and configures keepalived"

depends          'apt', '>= 2.3.8'
depends          'yum', '>= 3.1.4'
depends          'yum-epel', '>= 0.3.4'

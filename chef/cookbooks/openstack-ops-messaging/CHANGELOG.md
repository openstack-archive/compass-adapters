# CHANGELOG for cookbook-openstack-ops-messaging

This file is used to list changes made in each version of cookbook-openstack-ops-messaging.

## 9.0.1
### Bug
* Fix the depends cookbook version issue in metadata.rb

## 9.0.0
* Upgrade to Icehouse

## 8.0.1:
* Add change_password to make rabbitmq work when develop_mode=false

## 8.0.0
* upgrade to Havana

## 7.0.1:

* default the node['openstack'][*]['rabbit'] attributes for all the services
  using rabbitmq (block-storage, compute, image, metering, network) to whatever
  node['openstack']['mq'] attributes are set.

## 7.0.0

* Initial release intended for Grizzly-based OpenStack releases,
  for use with Stackforge upstream repositories.

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.

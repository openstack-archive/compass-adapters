default['ceph']['config'] = {}
default['ceph']['config-sections'] = {}
default['ceph']['config']['keystone']['rgw keystone accepted roles'] = 'admin, _member_'
default['ceph']['config']['keystone']['rgw keystone token cache size'] = 500
default['ceph']['config']['keystone']['rgw keystone revocation interval'] = 600
default['ceph']['config']['keystone']['nss db path'] = '/var/ceph/nss'
default['ceph']['config']['keystone']['rgw keystone admin token'] = 'openstack_identity_bootstrap_token'
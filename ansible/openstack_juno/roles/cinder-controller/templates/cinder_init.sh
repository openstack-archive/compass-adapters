keystone --os-token={{ ADMIN_TOKEN }} --os-endpoint=http://{{ identity_host }}:35357/v2.0 user-create --name=cinder --pass={{ CINDER_PASS }} --email=cinder@example.com
keystone --os-token={{ ADMIN_TOKEN }} --os-endpoint=http://{{ identity_host }}:35357/v2.0 user-role-add --user=cinder --tenant=service --role=admin

keystone --os-token={{ ADMIN_TOKEN }} --os-endpoint=http://{{ identity_host }}:35357/v2.0 service-create --name=cinder --type=volume --description="OpenStack Block Storage"
keystone --os-token={{ ADMIN_TOKEN }} --os-endpoint=http://{{ identity_host }}:35357/v2.0 endpoint-create --service-id=$(keystone --os-token={{ ADMIN_TOKEN }} --os-endpoint=http://{{ identity_host }}:35357/v2.0 service-list | awk '/ volume / {print $2}') --publicurl=http://{{ storage_controller_host }}:8776/v1/%\(tenant_id\)s --internalurl=http://{{ storage_controller_host }}:8776/v1/%\(tenant_id\)s --adminurl=http://{{ storage_controller_host }}:8776/v1/%\(tenant_id\)s


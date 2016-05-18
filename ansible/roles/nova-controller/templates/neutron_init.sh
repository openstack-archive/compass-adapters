##############################################################################
# Copyright (c) 2016 HUAWEI TECHNOLOGIES CO.,LTD and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
# neutron --os-username=admin --os-password={{ ADMIN_PASS }} --os-tenant-name=admin --os-auth-url=http://{{ identity_host }}:35357/v2.0 net-create ext-net --shared --router:external=True

# neutron --os-username=admin --os-password={{ ADMIN_PASS }} --os-tenant-name=admin --os-auth-url=http://{{ identity_host }}:35357/v2.0 subnet-create ext-net --name ext-subnet --allocation-pool start={{ FLOATING_IP_START }},end={{ FLOATING_IP_END}} --disable-dhcp --gateway {{EXTERNAL_NETWORK_GATEWAY}} {{EXTERNAL_NETWORK_CIDR}}


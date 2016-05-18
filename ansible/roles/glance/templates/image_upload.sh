##############################################################################
# Copyright (c) 2016 HUAWEI TECHNOLOGIES CO.,LTD and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
sleep 10
glance --os-username=admin --os-password={{ ADMIN_PASS }} --os-tenant-name=admin --os-auth-url=http://{{ internal_vip.ip }}:35357/v2.0 image-create --name="cirros" --disk-format=qcow2 --container-format=bare --is-public=true < /opt/{{ build_in_image_name }} && touch glance.import.completed

#!/bin/bash
##############################################################################
# Copyright (c) 2016 HUAWEI TECHNOLOGIES CO.,LTD and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
services=`cat /opt/service | uniq`
for service in $services; do
    /usr/sbin/service $service status >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        /usr/sbin/service $service start
    fi
done

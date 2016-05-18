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
    if [ `/sbin/initctl list|awk '/stop\/waiting/{print $1}'|uniq | grep $service` ]; then
        /sbin/start $service
    fi
done

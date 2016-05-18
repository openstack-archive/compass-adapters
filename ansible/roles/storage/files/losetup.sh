##############################################################################
# Copyright (c) 2016 HUAWEI TECHNOLOGIES CO.,LTD and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
loop_dev=`losetup -a |grep "/var/storage.img"|awk -F':' '{print $1}'`
if [ -z $loop_dev ]; then
  losetup -f --show /var/storage.img
else
  echo $loop_dev
fi


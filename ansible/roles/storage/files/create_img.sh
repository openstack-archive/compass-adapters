##############################################################################
# Copyright (c) 2016 HUAWEI TECHNOLOGIES CO.,LTD and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
seek_num=`echo $1 | sed -e 's/.* //g'`
if [ ! -f /var/storage.img ]; then
  dd if=/dev/zero of=/var/storage.img bs=1 count=0 seek=$seek_num
fi

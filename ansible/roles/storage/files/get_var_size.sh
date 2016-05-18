##############################################################################
# Copyright (c) 2016 HUAWEI TECHNOLOGIES CO.,LTD and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
size=`df /var | awk '$3 ~ /[0-9]+/ { print $4 }'`;
if [ $size -gt 2000000000 ]; then
  echo -n 2000000000000;
else
  echo -n $((size * 1000 / 512 * 512));
fi

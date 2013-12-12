#!/bin/bash

modinfo openvswitch |grep 56D59658C3B9FADCD146B12
if [ $? -eq 0 ]; then
    cd /tmp/openvswitch
    
    yum localinstall -y /tmp/openvswitch/kmod-openvswitch-1.11.0-1.el6.x86_64.rpm
    yum localinstall -y /tmp/openvswitch/openvswitch-1.11.0-1.x86_64.rpm
    service openvswitch start
    modinfo openvswitch
    
    cd /tmp
    rm -rf /tmp/openvswitch
fi


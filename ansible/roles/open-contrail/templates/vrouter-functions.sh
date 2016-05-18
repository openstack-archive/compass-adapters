#!/bin/bash
##############################################################################
# Copyright (c) 2016 HUAWEI TECHNOLOGIES CO.,LTD and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

source /etc/contrail/agent_param

function pkt_setup () {
    for f in /sys/class/net/$1/queues/rx-*
    do
        q="$(echo $f | cut -d '-' -f2)"
        r=$(($q%32))
        s=$(($q/32))
        ((mask=1<<$r))
        str=(`printf "%x" $mask`)
        if [ $s -gt 0 ]; then
            for ((i=0; i < $s; i++))
            do
                str+=,00000000
            done
        fi
        echo $str > $f/rps_cpus
    done
}

function insert_vrouter() {
    if cat $CONFIG | grep '^\s*platform\s*=\s*dpdk\b' &>/dev/null; then
        vrouter_dpdk_start
        return $?
    fi

    grep $kmod /proc/modules 1>/dev/null 2>&1
    if [ $? != 0 ]; then 
        insmod /var/lib/dkms/vrouter/2.21/build/vrouter.ko
        if [ $? != 0 ]
        then
            echo "$(date) : Error inserting vrouter module"
            return 1
        fi

        if [ -f /sys/class/net/pkt1/queues/rx-0/rps_cpus ]; then
            pkt_setup pkt1
        fi
        if [ -f /sys/class/net/pkt2/queues/rx-0/rps_cpus ]; then
            pkt_setup pkt2
        fi
        if [ -f /sys/class/net/pkt3/queues/rx-0/rps_cpus ]; then
            pkt_setup pkt3
        fi
    fi

    # check if vhost0 is not present, then create vhost0 and $dev
    if [ ! -L /sys/class/net/vhost0 ]; then
        echo "$(date): Creating vhost interface: $DEVICE."
        # for bonding interfaces
        loops=0
        while [ ! -f /sys/class/net/$dev/address ]
        do
            sleep 1
            loops=$(($loops + 1))
            if [ $loops -ge 60 ]; then
                echo "Unable to look at /sys/class/net/$dev/address"
                return 1
            fi
        done

        DEV_MAC=$(cat /sys/class/net/$dev/address)
        vif --create $DEVICE --mac $DEV_MAC
        if [ $? != 0 ]; then
            echo "$(date): Error creating interface: $DEVICE"
        fi


        echo "$(date): Adding $dev to vrouter"
        DEV_MAC=$(cat /sys/class/net/$dev/address)
        vif --add $dev --mac $DEV_MAC --vrf 0 --vhost-phys --type physical
        if [ $? != 0 ]; then
            echo "$(date): Error adding $dev to vrouter"
        fi

        vif --add $DEVICE --mac $DEV_MAC --vrf 0 --type vhost --xconnect $dev
        if [ $? != 0 ]; then
            echo "$(date): Error adding $DEVICE to vrouter"
        fi
    fi
    return 0
}

function vrouter_dpdk_start() {
    # wait for vRouter/DPDK to start
    echo "$(date): Waiting for vRouter/DPDK to start..."
    service ${VROUTER_SERVICE} start
    loops=0
    while ! is_vrouter_dpdk_running
    do
        sleep 1
        loops=$(($loops + 1))
        if [ $loops -ge 60 ]; then
            echo "No vRouter/DPDK running."
            echo "Please check if ${VROUTER_SERVICE} service is up and running."
            return 1
        fi
    done

    # TODO: at the moment we have no interface deletion, so this loop might
    #       be unnecessary in the future
    echo "$(date): Waiting for Agent to configure $DEVICE..."
    loops=0
    while [ ! -L /sys/class/net/vhost0 ]
    do
        sleep 1
        loops=$(($loops + 1))
        if [ $loops -ge 10 ]; then
            break
        fi
    done

    # check if vhost0 is not present, then create vhost0 and $dev
    if [ ! -L /sys/class/net/vhost0 ]; then
        echo "$(date): Creating vhost interface: $DEVICE."
        agent_conf_read

        DEV_MAC=${physical_interface_mac}
        DEV_PCI=${physical_interface_address}

        if [ -z "${DEV_MAC}" -o -z "${DEV_PCI}" ]; then
            echo "No device configuration found in ${CONFIG}"
            return 1
        fi

        # TODO: the vhost creation is happening later in vif --add
#        vif --create $DEVICE --mac $DEV_MAC
#        if [ $? != 0 ]; then
#            echo "$(date): Error creating interface: $DEVICE"
#        fi

        echo "$(date): Adding $dev to vrouter"
        # add DPDK ethdev 0 as a physical interface
        vif --add 0 --mac $DEV_MAC --vrf 0 --vhost-phys --type physical --pmd --id 0
        if [ $? != 0 ]; then
            echo "$(date): Error adding $dev to vrouter"
        fi

        # TODO: vif --xconnect seems does not work without --id parameter?
        vif --add $DEVICE --mac $DEV_MAC --vrf 0 --type vhost --xconnect 0 --pmd --id 1
        if [ $? != 0 ]; then
            echo "$(date): Error adding $DEVICE to vrouter"
        fi
    fi
    return 0
}

DPDK_BIND=/opt/contrail/bin/dpdk_nic_bind.py
VROUTER_SERVICE="supervisor-vrouter"

function is_vrouter_dpdk_running() {
    # check for NetLink TCP socket
    lsof -ni:20914 -sTCP:LISTEN > /dev/null

    return $?
}

function agent_conf_read() {
    eval `cat ${CONFIG} | grep -E '^\s*physical_\w+\s*='`
}

function vrouter_dpdk_if_bind() {
    if [ ! -s /sys/class/net/${dev}/address ]; then
        echo "No ${dev} device found."
        ${DPDK_BIND} --status
        return 1
    fi

    modprobe igb_uio
    # multiple kthreads for port monitoring
    modprobe rte_kni kthread_mode=multiple

    ${DPDK_BIND} --force --bind=igb_uio $dev
    ${DPDK_BIND} --status
}

function vrouter_dpdk_if_unbind() {
    if [ -s /sys/class/net/${dev}/address ]; then
        echo "Device ${dev} is already unbinded."
        ${DPDK_BIND} --status
        return 1
    fi

    agent_conf_read

    DEV_PCI=${physical_interface_address}
    DEV_DRIVER=`lspci -vmmks ${DEV_PCI} | grep 'Module:' | cut -d $'\t' -f 2`

    if [ -z "${DEV_DRIVER}" -o -z "${DEV_PCI}" ]; then
        echo "No device ${dev} configuration found in ${AGENT_DPDK_PARAMS_FILE}"
        return 1
    fi

    # wait for vRouter/DPDK to stop
    echo "$(date): Waiting for vRouter/DPDK to stop..."
    loops=0
    while is_vrouter_dpdk_running
    do
        sleep 1
        loops=$(($loops + 1))
        if [ $loops -ge 60 ]; then
            echo "vRouter/DPDK is still running."
            echo "Please try to stop ${VROUTER_SERVICE} service."
            return 1
        fi
    done

    ${DPDK_BIND} --force --bind=${DEV_DRIVER} ${DEV_PCI}
    ${DPDK_BIND} --status

    rmmod rte_kni
    rmmod igb_uio
}

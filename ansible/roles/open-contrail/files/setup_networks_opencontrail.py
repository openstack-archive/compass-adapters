import yaml
import netaddr
import os
import log as logging

LOG = logging.getLogger("net-init-opencontrail")
config_path = os.path.join(os.path.dirname(__file__), "network.cfg")

def setup_bondings(bond_mappings):
    print bond_mappings

def add_vlan_link(interface, ifname, vlan_id):
    LOG.info("add_vlan_link enter")
    cmd = "ip link add link %s name %s type vlan id %s; " % (ifname, interface, vlan_id)
    cmd += "ip link set %s up; ip link set %s up" % (interface, ifname)
    LOG.info("add_vlan_link: cmd=%s" % cmd)
    os.system(cmd)

#def add_ovs_port(ovs_br, ifname, uplink, vlan_id=None):
#    LOG.info("add_ovs_port enter")
#    cmd = "ovs-vsctl --may-exist add-port %s %s" % (ovs_br, ifname)
#    if vlan_id:
#        cmd += " tag=%s" % vlan_id
#    cmd += " -- set Interface %s type=internal;" % ifname
#    cmd += "ip link set dev %s address `ip link show %s |awk '/link\/ether/{print $2}'`;" \
#            % (ifname, uplink)
#    cmd += "ip link set %s up;" % ifname
#    LOG.info("add_ovs_port: cmd=%s" % cmd)
#    os.system(cmd)

def setup_intfs(sys_intf_mappings, uplink_map):
    LOG.info("setup_intfs enter")
    for intf_name, intf_info in sys_intf_mappings.items():
        if intf_info["type"] == "vlan":
            add_vlan_link(intf_name, intf_info["interface"], intf_info["vlan_tag"])
#        elif intf_info["type"] == "ovs":
#            add_ovs_port(
#                    intf_info["interface"],
#                    intf_name,
#                    uplink_map[intf_info["interface"]],
#                    vlan_id=intf_info.get("vlan_tag"))
        else:
            pass

def setup_ips(ip_settings, sys_intf_mappings):
    LOG.info("setup_ips enter")
    for intf_info in ip_settings.values():
        network = netaddr.IPNetwork(intf_info["cidr"])
        if sys_intf_mappings[intf_info["name"]]["type"] == "ovs":
            intf_name = intf_info["name"]
        else:
            intf_name = intf_info["alias"]
        if "gw" in intf_info:
            continue
        cmd = "ip addr add %s/%s brd %s dev %s;" \
              % (intf_info["ip"], intf_info["netmask"], str(network.broadcast),intf_name)
#        if "gw" in intf_info:
#            cmd += "route del default;"
#            cmd += "ip route add default via %s dev %s" % (intf_info["gw"], intf_name)
        LOG.info("setup_ips: cmd=%s" % cmd)
        os.system(cmd)

def setup_ips_new(config):
    LOG.info("setup_ips_new enter")
    network = netaddr.IPNetwork(config["ip_settings"]["br-prv"]["cidr"])
    intf_name = config["provider_net_mappings"][0]["interface"]
    cmd = "ip addr add %s/%s brd %s dev %s;" \
          % (config["ip_settings"]["br-prv"]["ip"], config["ip_settings"]["br-prv"]["netmask"], str(network.broadcast), intf_name)
#    cmd = "ip link set br-ex up;"
#    cmd += "ip addr add %s/%s brd %s dev %s;" \
#          % (config["ip_settings"]["br-prv"]["ip"], config["ip_settings"]["br-prv"]["netmask"], str(network.broadcast), 'br-ex')
    cmd += "route del default;"
    cmd += "ip route add default via %s dev %s" % (config["ip_settings"]["br-prv"]["gw"], intf_name)
#    cmd += "ip route add default via %s dev %s" % (config["ip_settings"]["br-prv"]["gw"], 'br-ex')
    LOG.info("setup_ips_new: cmd=%s" % cmd)
    os.system(cmd)

def setup_default_router(config):
    LOG.info("setup_ips_new enter")
    network = netaddr.IPNetwork(config["ip_settings"]["br-prv"]["cidr"])
    intf_name = config["provider_net_mappings"][0]["interface"]
    cmd = "route del default;"
    cmd += "ip route add default via %s dev %s" % (config["ip_settings"]["br-prv"]["gw"], "vhost0")
    LOG.info("setup_default_router: cmd=%s" % cmd)
    os.system(cmd)

def remove_ovs_kernel_mod(config):
    LOG.info("remove_ovs_kernel_mod enter")
    cmd = "rmmod vport_vxlan; rmmod openvswitch;"
    LOG.info("remove_ovs_kernel_mod: cmd=%s" % cmd)
    os.system(cmd)

def main(config):
    uplink_map = {}
    setup_bondings(config["bond_mappings"])
    remove_ovs_kernel_mod(config)
    for provider_net in config["provider_net_mappings"]:
        uplink_map[provider_net['name']] = provider_net['interface']

    setup_intfs(config["sys_intf_mappings"], uplink_map)
    setup_ips(config["ip_settings"], config["sys_intf_mappings"])
#    setup_ips_new(config)
    setup_default_router(config)

if __name__ == "__main__":
    config = yaml.load(open(config_path))
    main(config)

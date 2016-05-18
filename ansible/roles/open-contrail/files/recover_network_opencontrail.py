import yaml
import netaddr
import os
import log as logging

LOG = logging.getLogger("net-recover-opencontrail")
config_path = os.path.join(os.path.dirname(__file__), "network.cfg")

def setup_bondings(bond_mappings):
    print bond_mappings

def setup_ips_new(config):
    LOG.info("setup_ips_new enter")
    network = netaddr.IPNetwork(config["ip_settings"]["br-prv"]["cidr"])
    intf_name = config["provider_net_mappings"][0]["interface"]
    cmd = "ip addr add %s/%s brd %s dev %s;" \
          % (config["ip_settings"]["br-prv"]["ip"], config["ip_settings"]["br-prv"]["netmask"], str(network.broadcast), intf_name)
    #cmd = "ip link set br-ex up;"
    #cmd += "ip addr add %s/%s brd %s dev %s;" \
    #      % (config["ip_settings"]["br-prv"]["ip"], config["ip_settings"]["br-prv"]["netmask"], str(network.broadcast), 'br-ex')
    cmd += "route del default;"
    cmd += "ip route add default via %s dev %s" % (config["ip_settings"]["br-prv"]["gw"], intf_name)
    #cmd += "ip route add default via %s dev %s" % (config["ip_settings"]["br-prv"]["gw"], 'br-ex')
    LOG.info("setup_ips_new: cmd=%s" % cmd)
    os.system(cmd)


def main(config):
    setup_ips_new(config)    

if __name__ == "__main__":
    config = yaml.load(open(config_path))
    main(config)

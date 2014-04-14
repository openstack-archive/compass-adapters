# Kickstart for Profile: CentOS6.4_x86-64-1
# Distro: CentOS6.4

# System Authorization
auth --useshadow --enablemd5

# System Bootloader
bootloader --location=mbr

# Clear MBR
zerombr

# Pre-clear Partition
clearpart --all --initlabel

# Use Text Mode
text
# cmdline

# Disable Firewall
firewall --disabled

# Run the Setup Agent on first-boot
firstboot --disable

# System Keyboard
keyboard us

# Language Setting
lang en_US

# Installation Loggin Level
logging --level=info

# Network Installation
url --url=$tree


$SNIPPET('network_config')

# Repository Config
repo --name=ppa_repo --baseurl=http://$server:$http_port/cobbler/repo_mirror/ppa_repo/

# Root Password
#if $getVar('password', '') != ""
rootpw --iscrypted $password
#else
rootpw root
#end if

# Selinux Disable
selinux --disabled

# No X Window System
skipx

# System Timezone
#if $getVar('timezone', '') != ""
timezone --utc $timezone
#else
timezone --utc US/Pacific
#end if

# Install
install

# Reboot After Installation
reboot

%include /tmp/part-include

%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
# useful to debug pre/post
# chvt 3
# exec < /dev/tty3 > /dev/tty3 2>/dev/tty3

# get  the number of hard disks and their names

$SNIPPET('partition_disks')

# Packages
%packages --nobase
@core 
iproute
chef
ntp
openssh-clients
wget
json-c
libestr
libgt
liblogging
rsyslog

%post --log=/var/log/post_install.log
$SNIPPET('post_install_network_config')

cat << EOF > /etc/yum.conf
$SNIPPET('yum.conf')
EOF

$SNIPPET('ssh')
$SNIPPET('ntp')

chkconfig iptables off
chkconfig ip6tables off

cat << EOF > /etc/security/limits.conf
$SNIPPET('limits.conf')
EOF

cat << EOF > /etc/sysctl.conf
$SNIPPET('sysctl.conf')
EOF

sysctl -p

$SNIPPET($tool)

$SNIPPET('post_anamon')
$SNIPPET('kickstart_done')

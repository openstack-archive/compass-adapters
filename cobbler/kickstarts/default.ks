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
timezone --utc US/Pacific

# Install
install

# Reboot After Installation
reboot

%include /tmp/part-include

%pre
$SNIPPET('log_ks_pre')
$kickstart_start
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
# useful to debug pre/post
# chvt 3
# exec < /dev/tty3 > /dev/tty3 2>/dev/tty3

# get  the number of hard disks and their names

$SNIPPET('partition_disks')

# Packages
# %packages --ignoremissing --nobase
%packages --nobase
@core 
iproute
chef-11.8.0-1.el6.x86_64
ntp
openssh-clients
wget


%post --log=/var/log/post_install.log
#if $getVar('passwd', '') != ""
    #set $passwd = $passwd.strip()
/usr/sbin/useradd -p '$passwd' $user
#end if

$SNIPPET('post_install_network_config')

cat << EOF > /etc/yum.conf
$SNIPPET('yum.conf')
EOF

chkconfig ntpd on
chkconfig iptables off
chkconfig ip6tables off

cat << EOF > /etc/ntp.conf
$SNIPPET('ntp.conf')
EOF

## $yum_repo_stanza
## $yum_config_stanza

$SNIPPET($tool)

# rm -rf /etc/yum.repos.d/CentOS-Base.repo


$SNIPPET('post_anamon')
$SNIPPET('kickstart_done')

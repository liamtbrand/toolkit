#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Configuration
user="pi"
group="pi"

#cat >/etc/myconfig.conf <<EOL
#line 1, ${kernel}
#line 2, 
#line 3, ${distro}
#line 4 line
#... 
#EOL

# Apply SSH configuration
authorized_keys_path=/home/${user}/.ssh/authorized_keys
touch ${authorized_keys_path}
chmod 600 ${authorized_keys_path}
chown ${user}:${group} ${authorized_keys_path}
cat >${authorized_keys_path} <<EOL
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGkoH5O6/HcGDjHRdWXwkp3V+RAlmQD5ognmIFMRlJetc0yZp61MZkForqvMFR8q+bS2Gje+Ass/jiljMhA1c5ADCQs6Z1ARnFRemmg19o1qOkyao/R/kf+e5PO54x7sbzYT5oYumLjEL2Gp+7BZcg1cLqEmQG/aC3uCJNT8orS4WPko9PfZKFj6ydEoo/aDudqosv3mI/R40bo6EksScAYDpQvalJ4jE3zphXj0vXCT4bFWi4CAv7F8GSwjN6NUU1Q1uRrDsP4HK4k1S9y3jP08XDLmxFthWUPX7OFVA1yJKMVh5lgjuS5yijK3DjvaV8QZk2YJ5JpuNyp7SquCCV liambrand@Liams-MacBook-Pro.local
EOL

cat >/etc/ssh/sshd_config <<EOL
#	\$OpenBSD: sshd_config,v 1.103 2018/04/09 20:41:22 tj Exp \$

# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/bin:/bin:/usr/sbin:/sbin

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

Include /etc/ssh/sshd_config.d/*.conf

#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
#PermitRootLogin prohibit-password
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

#PubkeyAuthentication yes

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
#AuthorizedKeysFile	.ssh/authorized_keys .ssh/authorized_keys2

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication no
#PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
ChallengeResponseAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
PrintMotd no
#PrintLastLog yes
#TCPKeepAlive yes
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# override default of no subsystems
Subsystem	sftp	/usr/lib/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#	X11Forwarding no
#	AllowTcpForwarding no
#	PermitTTY no
#	ForceCommand cvs server
EOL

# Install fail2ban
apt install -y fail2ban
cat >/etc/fail2ban/jail.d/sshd.local <<EOL
[sshd]
enabled = true
port = ssh
action = iptables-multiport
logpath = /var/log/secure
maxretry = 3
bantime = 600
EOL
systemctl enable fail2ban

# Install firewall (ufw)
apt install -y ufw
ufw allow ssh
ufw enable

echo "Rebooting..."
reboot 10
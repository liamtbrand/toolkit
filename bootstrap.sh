#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Configuration
username="pi"

#cat >/etc/myconfig.conf <<EOL
#line 1, ${kernel}
#line 2, 
#line 3, ${distro}
#line 4 line
#... 
#EOL

# Apply SSH configuration
cat >/home/${username}/.ssh/known_hosts <<EOL
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGkoH5O6/HcGDjHRdWXwkp3V+RAlmQD5ognmIFMRlJetc0yZp61MZkForqvMFR8q+bS2Gje+Ass/jiljMhA1c5ADCQs6Z1ARnFRemmg19o1qOkyao/R/kf+e5PO54x7sbzYT5oYumLjEL2Gp+7BZcg1cLqEmQG/aC3uCJNT8orS4WPko9PfZKFj6ydEoo/aDudqosv3mI/R40bo6EksScAYDpQvalJ4jE3zphXj0vXCT4bFWi4CAv7F8GSwjN6NUU1Q1uRrDsP4HK4k1S9y3jP08XDLmxFthWUPX7OFVA1yJKMVh5lgjuS5yijK3DjvaV8QZk2YJ5JpuNyp7SquCCV liambrand@Liams-MacBook-Pro.local
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
#!/bin/bash -xe

# Enable ip forwarding and nat
sysctl -w net.ipv4.ip_forward=1

# Make forwarding persistent.
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sed -i= 's/^[# ]*net.ipv4.ip_forward=[[:digit:]]/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

yum -y update

# Install nginx for instance http health check
yum -y install nginx

ENABLE_SQUID="${squid_enabled}"

if [[ "$$ENABLE_SQUID" == "true" ]]; then
  yum -y install squid3

  cat - > /etc/squid/squid.conf <<'EOM'
${file("${squid_config == "" ? "${format("%s/config/squid.conf", module_path)}" : squid_config}")}
EOM

  systemctl reload squid
fi

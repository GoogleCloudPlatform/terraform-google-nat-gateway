#!/usr/bin/env bash

set -x
set -e

NAT_IP=${NAT_IP:-$(terraform output ip-nat-gateway)}
LB_IP=${LB_IP:-$(terraform output ip-lb)}

count=0
IP=""
while [[ $count -lt 600 && "${IP}" != "${NAT_IP}" ]]; do
  echo "INFO: Waiting for NAT IP to match ${NAT_IP}..."
  IP=$(curl -sf ${LB_IP}/ip.php || true)
  ((count=count+1))
  sleep 10
done
test $count -lt 600

echo "PASS"

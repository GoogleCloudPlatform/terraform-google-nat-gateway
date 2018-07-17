#!/usr/bin/env bash

set -x
set -e

declare -a EXTERNAL_IPS
EXTERNAL_IPS[0]=${EXTERNAL_IP_1:-$(terraform output ip-nat-production)}
EXTERNAL_IPS[1]=${EXTERNAL_IP_2:-$(terraform output ip-nat-staging)}

LB_IP=${LB_IP:-$(terraform output ip-lb)}

echo "INFO: Verifying all NAT IPs: ${EXTERNAL_IPS[*]}"

count=0
while [[ $count -lt 600 && ${#EXTERNAL_IPS[@]} -gt 0 ]]; do
  IP=$(curl -sf http://${LB_IP}/ip.php || true)
  if [[ "${IP}" == ${EXTERNAL_IPS[0]} ]]; then
    echo "INFO: Found NAT IP: ${IP}"
    EXTERNAL_IPS=("${EXTERNAL_IPS[@]:1}")
  fi
  ((count=count+1))
  sleep 10
done
test $count -lt 600

echo "PASS: All NAT IPs found"

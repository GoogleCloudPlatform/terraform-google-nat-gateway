#!/usr/bin/env bash

set -x
set -e

function cleanup() {
  set +e
  killall -9 kubectl
  kubectl delete deploy proxy
}
trap cleanup EXIT

declare -a EXTERNAL_IPS
EXTERNAL_IPS[0]=${EXTERNAL_IP_1:-$(terraform output ip-nat-zone-1)}
EXTERNAL_IPS[1]=${EXTERNAL_IP_2:-$(terraform output ip-nat-zone-2)}
EXTERNAL_IPS[2]=${EXTERNAL_IP_3:-$(terraform output ip-nat-zone-3)}

# Create squid pod to tunnel through
kubectl run proxy --port 1080 --image xkuma/socks5
kubectl wait deploy/proxy --for condition=available
kubectl port-forward deploy/proxy 1080:1080 &

echo "INFO: Verifying all NAT IPs: ${EXTERNAL_IPS[*]}"

count=0
while [[ $count -lt 1200 && ${#EXTERNAL_IPS[@]} -gt 0 ]]; do
  IP=$(curl -m 5 -s --socks5-hostname localhost:1080 http://ipinfo.io/ip || true)
  if [[ "${IP}" == ${EXTERNAL_IPS[0]} ]]; then
    echo "INFO: Found NAT IP: ${IP}"
    EXTERNAL_IPS=("${EXTERNAL_IPS[@]:1}")
  fi
  ((count=count+1))
  sleep 0.7
done
test $count -lt 1200

echo "PASS: All NAT IPs found"

#!/usr/bin/env bash

set -x
set -e

function cleanup() {
  set +e
  rm -f ssh_config
  killall -9 autossh
  killall -9 ssh
  kill $SSH_AGENT_PID
}
trap cleanup EXIT

declare -a EXTERNAL_IPS
EXTERNAL_IPS[0]=${EXTERNAL_IP_1:-$(terraform output ip-nat-zone-1)}
EXTERNAL_IPS[1]=${EXTERNAL_IP_2:-$(terraform output ip-nat-zone-2)}
EXTERNAL_IPS[2]=${EXTERNAL_IP_3:-$(terraform output ip-nat-zone-3)}

NAT_HOST=${NAT_HOST:-$(terraform output nat-host)}
REMOTE_HOST_URI=${REMOTE_HOST_URI:-$(terraform output remote-host-uri)}
REMOTE_HOST=${REMOTE_HOST_URI//*instances\//}
REMOTE_ZONE=$(echo ${REMOTE_HOST_URI} | cut -d/ -f9)

# Configure SSH
SSH_USER_EMAIL=$(gcloud config get-value account)
SSH_USER=${SSH_USER_EMAIL//@*}

cat > ssh_config << EOF
Host *
  User ${SSH_USER}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host remote
  HostName ${EXTERNAL_IPS[0]}
  ProxyCommand gcloud compute ssh ${SSH_USER}@${NAT_HOST} --ssh-flag="-A -W ${REMOTE_HOST}:22"
  DynamicForward 1080
EOF

if [[ ! -f ${HOME}/.ssh/google_compute_engine ]]; then
  mkdir -p ${HOME}/.ssh && chmod 0700 ${HOME}/.ssh && \
  ssh-keygen -b 2048 -t rsa -f ${HOME}/.ssh/google_compute_engine -q -N "" -C ${SSH_USER_EMAIL}
fi
eval `ssh-agent`
ssh-add ${HOME}/.ssh/google_compute_engine
gcloud compute config-ssh
export AUTOSSH_LOGFILE=/dev/stderr
autossh -M 20000 -f -N -F ${PWD}/ssh_config remote

echo "INFO: Verifying all NAT IPs: ${EXTERNAL_IPS[*]}"

count=0
while [[ $count -lt 180 && ${#EXTERNAL_IPS[@]} -gt 0 ]]; do
  IP=$(curl -m 5 -s --socks5 localhost:1080 http://ipinfo.io/ip || true)
  if [[ "${IP}" == ${EXTERNAL_IPS[0]} ]]; then
    echo "INFO: Found NAT IP: ${IP}"
    EXTERNAL_IPS=("${EXTERNAL_IPS[@]:1}")
  fi
  ((count=count+1))
  sleep 1
done
test $count -lt 180

echo "PASS: All NAT IPs found"

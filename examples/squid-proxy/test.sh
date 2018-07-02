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

NAT_IP=${EXTERNAL_IP:-$(terraform output nat-ip)}

NAT_HOST_URI=${NAT_HOST:-$(terraform output nat-host)}
NAT_HOST=${NAT_HOST_URI//*instances\//}
REMOTE_HOST_URI=${REMOTE_HOST_URI:-$(terraform output vm-host)}
REMOTE_HOST=${REMOTE_HOST_URI//*instances\//}
REMOTE_ZONE=$(echo ${REMOTE_HOST_URI} | cut -d/ -f9)

# Configure SSH
SSH_USER_EMAIL=$(gcloud config get-value account)
SSH_USER=${SSH_USER_EMAIL//@*}


if [[ ! -f ${HOME}/.ssh/google_compute_engine ]]; then
  mkdir -p ${HOME}/.ssh && chmod 0700 ${HOME}/.ssh && \
  ssh-keygen -b 2048 -t rsa -f ${HOME}/.ssh/google_compute_engine -q -N "" -C ${SSH_USER_EMAIL}
fi

# Create ssh tunnel through NAT gateway.

cat > ssh_config << EOF
Host *
    User ${SSH_USER}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host remote
    HostName ${NAT_IP}
    ProxyCommand gcloud compute ssh ${SSH_USER}@${NAT_HOST_URI} --ssh-flag="-A -W ${REMOTE_HOST}:22"
    LocalForward 3128 ${NAT_HOST}:3128
EOF

eval `ssh-agent`
ssh-add ${HOME}/.ssh/google_compute_engine
gcloud compute config-ssh
export AUTOSSH_LOGFILE=/dev/stderr
autossh -M 20000 -f -N -F ${PWD}/ssh_config remote

echo "INFO: Verifying NAT IP through squid proxy: ${NAT_IP}"

count=0
while [[ $count -lt 60 ]]; do
  IP=$(curl -m 5 -s --proxy localhost:3128 http://ipinfo.io/ip || true)
  if [[ "${IP}" == "${NAT_IP}" ]]; then
    echo "INFO: Found NAT IP: ${IP}"      
    break
  fi
  ((count=count+1))
  sleep 10
done
test $count -lt 60

echo "PASS: Egress from instance is routed through squid proxy."

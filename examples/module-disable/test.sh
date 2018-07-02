#!/usr/bin/env bash

set -x
set -e

MODE=$1

[[ "${MODE}" != "nat" && "${MODE}" != "direct" ]] && echo "USAGE: $0 <nat|direct>" && exit 1

function cleanup() {
  set +e
  rm -f ssh_config
  killall -9 autossh
  killall -9 ssh
  kill $SSH_AGENT_PID
}
trap cleanup EXIT

NAT_IP=${EXTERNAL_IP:-$(terraform output nat-ip)}

NAT_HOST=${NAT_HOST:-$(terraform output nat-host)}
REMOTE_HOST_IP=${REMOTE_HOST_IP:-$(terraform output vm-ip)}
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

if [[ "${MODE}" == "nat" ]]; then
  # Create ssh tunnel through NAT gateway.

  cat > ssh_config << EOF
Host *
  User ${SSH_USER}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  ConnectTimeout 5
  BatchMode yes

Host nat
  HostName ${NAT_IP}
  ProxyCommand gcloud compute ssh ${SSH_USER}@${NAT_HOST} --ssh-flag="-A -W ${REMOTE_HOST}:22"
  DynamicForward 1080
EOF

  eval `ssh-agent`
  ssh-add ${HOME}/.ssh/google_compute_engine
  gcloud compute config-ssh
  export AUTOSSH_LOGFILE=/dev/stderr
  autossh -M 20000 -f -N -F ${PWD}/ssh_config nat

  echo "INFO: Verifying NAT IP: ${NAT_IP}"

  count=0
  while [[ $count -lt 60 ]]; do
    IP=$(curl -m 5 -s --socks5 localhost:1080 http://ipinfo.io/ip || true)
    if [[ "${IP}" == "${NAT_IP}" ]]; then
      echo "INFO: Found NAT IP: ${IP}"      
      break
    fi
    ((count=count+1))
    sleep 10
  done
  test $count -lt 60

  echo "PASS: Egress from instance is routed through NAT IP."
fi

if [[ "${MODE}" == "direct" ]]; then
  echo "INFO: Verifying external IP is not NAT IP"

  # Create ssh tunnel with socks proxy to remote instance.

    cat > ssh_config << EOF
Host *
  User ${SSH_USER}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  ConnectTimeout 5
  BatchMode yes

Host remote
  HostName ${REMOTE_HOST_IP}
  DynamicForward 1081
EOF

  eval `ssh-agent`
  ssh-add ${HOME}/.ssh/google_compute_engine
  export AUTOSSH_LOGFILE=/dev/stderr
  autossh -M 20001 -f -N -F ${PWD}/ssh_config remote

  count=0
  while [[ $count -lt 60 ]]; do
    IP=$(curl -m 5 -s --socks5 localhost:1081 http://ipinfo.io/ip || true)
    if [[ -n "${IP}" && "${IP}" == "${REMOTE_HOST_IP}" ]]; then
      echo "INFO: IP check passed: ${IP}"
      break
    fi
    ((count=count+1))
    sleep 10
  done
  test $count -lt 60

  echo "PASS: Egress from instance is routed directly to internet."
fi

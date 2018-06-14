#!/usr/bin/env bash
set -e

MODE=$1

[[ "${MODE}" != "nat" && "${MODE}" != "direct" ]] && echo "USAGE: $0 <nat|direct>" && exit 1

function cleanup() {
  set +e
  rm -f ssh_config
  kill $ssh_pid
  kill $SSH_AGENT_PID
}
trap cleanup EXIT

function wait_for_port() {
  host=$1
  port=$2
  timeout=${3:-60}
  local count=0
  while test $count -lt $timeout && ! nc -z $host $port; do
    sleep 1
    ((count=count+1))
  done
  test $count -lt $timeout
}

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

Host nat
  HostName ${NAT_IP}
  ProxyCommand gcloud compute ssh ${SSH_USER}@${NAT_HOST} --ssh-flag="-A -W ${REMOTE_HOST}:22"
  DynamicForward 1080
EOF

  eval `ssh-agent`
  ssh-add ${HOME}/.ssh/google_compute_engine
  gcloud compute config-ssh
  ssh -N -F ssh_config nat &
  ssh_pid=$!

  wait_for_port localhost 1080 120

  echo "INFO: Verifying NAT IP: ${NAT_IP}"

  count=0
  while [[ $count -lt 60 ]]; do
    IP=$(curl -s --socks5 localhost:1080 http://ipinfo.io/ip || true)
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

Host remote
  HostName ${REMOTE_HOST_IP}
  DynamicForward 1080
EOF

  wait_for_port ${REMOTE_HOST_IP} 22 300

  eval `ssh-agent`
  ssh-add ${HOME}/.ssh/google_compute_engine
  ssh -N -F ssh_config remote &
  ssh_pid=$!

  wait_for_port localhost 1080 120

  count=0
  while [[ $count -lt 60 ]]; do
    IP=$(curl -s --socks5 localhost:1080 http://ipinfo.io/ip || true)
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
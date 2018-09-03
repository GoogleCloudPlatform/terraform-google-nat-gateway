#!/bin/bash

ws_input=$1

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function red() {
    printf "${RED}$1${NC}\n"
}

function green() {
    printf "${GREEN}$1${NC}\n"
}

[[ -z "${GOOGLE_PROJECT}" ]] && export GOOGLE_PROJECT=$(gcloud config get-value project)

CURR_DIR=$(basename "$PWD")
PARENT_DIR=$(basename "$(dirname "$PWD")")

cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "concourse-terraform-remote-backend"
    prefix = "terraform-google-nat-gateway"
  }
}
EOF

terraform init -get-plugins=true >/dev/null

function isStateEmpty() {
    terraform workspace select -no-color $1 >/dev/null
    terraform state pull >/dev/null
    [[ "$(terraform state list | wc -l)" -le 1 ]]
}

function cleanWorkspace() {
    local ws=$1
    echo "INFO: Checking workspace: $ws"
    if isStateEmpty $ws; then 
        green "INFO: $ws is clean"
    else
        red "WARN: $ws is not clean, destroying resources"
        terraform destroy -auto-approve
    fi
}

for ws in $(terraform workspace list | sed 's/[ *]//g'); do
    [[ -n "${ws_input}" && "$ws" != "${ws_input}" ]] && continue
    [[ "$ws" == "default" ]] && continue
    [[ "$ws" =~ -infra && "${PARENT_DIR}" != "infra" ]] && continue
    [[ ! "$ws" =~ -infra && "${PARENT_DIR}" != "examples" ]] && continue

    if [[ "${PARENT_DIR}" == "infra" && "$ws" =~ -infra ]]; then
        ### Infra cleanup ###

        case $ws in
        tf-ci-nat-gke-ha*-infra)
            [[ "${CURR_DIR}" =~ example-gke-ha-nat ]] && cleanWorkspace $ws
            continue
            ;;
        
        tf-ci-nat-gke*-infra)
            [[ "${CURR_DIR}" =~ example-gke-nat && "$ws" =~ ${CURR_DIR##*-} ]] && cleanWorkspace $ws
            continue
            ;;
        esac
    fi
    
    if [[ "${PARENT_DIR}" == "examples" && ! "$ws" =~ -infra ]]; then
        ### Example cleanup ###

        case $ws in
        tf-ci-nat-gke-ha-*)
            [[ "${CURR_DIR}" == "gke-ha-nat-gateway" ]] && cleanWorkspace $ws
            continue
            ;;
        tf-ci-nat-gke-*)
            if [[ "${CURR_DIR}" == "gke-nat-gateway" ]]; then
                export TF_VAR_gke_master_ip=0.0.0.0
                export TF_VAR_gke_node_tag=foo
                cleanWorkspace $ws
            fi
            continue
            ;;
        tf-ci-nat-ha*)
            [[ "${CURR_DIR}" == "ha-nat-gateway" ]] && cleanWorkspace $ws
            continue
            ;;
        tf-ci-nat-lb*)
            [[ "${CURR_DIR}" == "lb-http-nat-gateway" ]] && cleanWorkspace $ws
            continue
            ;;
        tf-ci-nat-module-disable*)
            [[ "${CURR_DIR}" == "module-disable" ]] && cleanWorkspace $ws
            continue
            ;;
        tf-ci-nat-multi-env*)
            [[ "${CURR_DIR}" == "multiple-nat-environments" ]] && cleanWorkspace $ws
            continue
            ;;
        tf-ci-nat-squid*)
            [[ "${CURR_DIR}" == "squid-proxy" ]] && cleanWorkspace $ws
            continue
            ;;
        esac
    fi
done

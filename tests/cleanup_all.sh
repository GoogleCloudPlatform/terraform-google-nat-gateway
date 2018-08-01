#!/bin/bash

READLINK=readlink
[[ $(uname -s) =~ Darwin ]] && READLINK=greadlink
SCRIPT_DIR="$(dirname "$(${READLINK} -f $0)")"

# Cleanup local terraform artifacts
find "${SCRIPT_DIR}/../" -type d -name ".terraform" -exec rm -rf "{}" \; 2>/dev/null
find "${SCRIPT_DIR}/../" -type f -name "terraform.tfstate*" -exec rm -f "{}" \; 2>/dev/null
find "${SCRIPT_DIR}/../" -type f -name "terraform.tfvars*" -exec rm -f "{}" \; 2>/dev/null

export GOOGLE_PROJECT=$(gcloud config get-value project)

OLDIFS=${IFS}

function exitClean() {
    IFS=$OLDIFS
}
trap exitClean EXIT

IFS=$'\n'

# Cleanup examples
for d in $(find "${SCRIPT_DIR}/../examples" -mindepth 1 -maxdepth 1 -type d | sort); do
    (cd "$d" && "../../tests/cleanup.sh")
done

# Cleanup infra
for d in $(find "${SCRIPT_DIR}/infra/" -mindepth 1 -maxdepth 1 -type d | sort); do
    (cd "$d" && "../../cleanup.sh")
done
#!/bin/bash -e

# Extract JSON args into shell variables
JQ=$(command -v jq || true)
[[ -z "${JQ}" ]] && echo "ERROR: Missing command: 'jq'" >&2 && exit 1

eval "$(${JQ} -r '@sh "REGION=\(.region)"')"

if [[ -n "${GOOGLE_CREDENTIALS}" && -n "${GOOGLE_PROJECT}" ]]; then
    gcloud auth activate-service-account --key-file <(echo "${GOOGLE_CREDENTIALS}") 2>/dev/null
    gcloud config set project "${GOOGLE_PROJECT}" 2>/dev/null
fi

export CLOUDSDK_CONTAINER_USE_V1_API_CLIENT=false

LATEST_MASTER=$(gcloud beta container get-server-config --region=${REGION} --format='value("validMasterVersions"[0])')
LATEST_NODE=$(gcloud beta container get-server-config --region=${REGION} --format='value("validNodeVersions"[0])')

# Output results in JSON format.
jq -n --arg latest_master_version "${LATEST_MASTER}" --arg latest_node_version "${LATEST_NODE}" '{"latest_master_version":$latest_master_version, "latest_node_version":$latest_node_version}'
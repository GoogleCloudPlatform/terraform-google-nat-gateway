#!/usr/bin/env bash
set -e
PIPELINE="tf-nat-gw-regression"
JOBS="check-nat-region-map run-example-gke-zonal run-example-gke-private run-example-gke-regional run-example-ha-nat-gateway run-example-lb-nat-gateway run-example-multi-env"
for j in $JOBS; do
  fly -t solutions trigger-job -j ${PIPELINE}/${j}
done

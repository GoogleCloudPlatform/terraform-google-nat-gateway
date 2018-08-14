#!/usr/bin/env bash

fly -t tf set-pipeline -p tf-nat-gw-regression -c tests/pipelines/tf-nat-gw-regression.yaml -l tests/pipelines/values.yaml
fly -t tf set-pipeline -p tf-nat-gw-cleanup -c tests/pipelines/tf-nat-gw-cleanup.yaml -l tests/pipelines/values.yaml
fly -t tf set-pipeline -p tf-nat-gw-pull-requests -c tests/pipelines/tf-nat-gw-pull-requests.yaml -l tests/pipelines/values.yaml

fly -t tf expose-pipeline -p tf-nat-gw-regression
fly -t tf expose-pipeline -p tf-nat-gw-pull-requests
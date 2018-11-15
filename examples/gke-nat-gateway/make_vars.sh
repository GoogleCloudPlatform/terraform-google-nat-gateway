#!/bin/bash -e
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific lan

cat > terraform.tfvars <<EOF
region        = "${REGION?Is not set}"
zone          = "${ZONE?Is not set}"
network       = "${NETWORK?Is not set}"
subnetwork    = "${SUBNETWORK?Is not set}"
gke_master_ip = "${MASTER_IP?Is not set}"
gke_node_tag  = "${NODE_TAG?Is not set}"
EOF
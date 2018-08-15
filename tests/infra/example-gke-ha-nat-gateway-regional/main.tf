/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable region {
  default = "us-west1"
}

variable zones {
  default = ["us-west1-a", "us-west1-b", "us-west1-c"]
}

variable network_name {
  default = "tf-ci-ha-nat-gke-regional"
}

data "google_client_config" "current" {}

provider google {
  region = "${var.region}"
}

data "google_container_engine_versions" "default" {
  zone = "${element(var.zones, 0)}"
}

resource "google_compute_network" "tf-ci" {
  name                    = "${var.network_name}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "tf-ci" {
  name          = "${var.network_name}"
  ip_cidr_range = "10.127.0.0/20"
  network       = "${google_compute_network.tf-ci.self_link}"
  region        = "${var.region}"

  private_ip_google_access = true
}

resource "google_container_cluster" "tf-ci" {
  name               = "tf-ci-regional"
  region             = "${var.region}"
  additional_zones   = ["${var.zones}"]
  initial_node_count = 1
  min_master_version = "${data.google_container_engine_versions.default.latest_node_version}"
  network            = "${google_compute_subnetwork.tf-ci.network}"
  subnetwork         = "${google_compute_subnetwork.tf-ci.name}"

  timeouts {
    create = "30m"
    delete = "30m"
  }
}

output network {
  value = "${google_compute_subnetwork.tf-ci.network}"
}

output subnetwork_name {
  value = "${google_compute_subnetwork.tf-ci.name}"
}

output cluster_name {
  value = "${google_container_cluster.tf-ci.name}"
}

output cluster_region {
  value = "${var.region}"
}

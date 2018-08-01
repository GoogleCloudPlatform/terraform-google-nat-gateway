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
  default = "us-east4"
}

variable zone {
  default = "us-east4-b"
}

variable network_name {
  default = "tf-ci-nat-gke-private"
}

data "google_client_config" "current" {}

provider google {
  region = "${var.region}"
}

data "google_container_engine_versions" "default" {
  zone = "${var.zone}"
}

resource "google_compute_network" "tf-ci" {
  name                    = "${var.network_name}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "tf-ci" {
  name                     = "${var.network_name}"
  ip_cidr_range            = "10.127.0.0/20"
  network                  = "${google_compute_network.tf-ci.self_link}"
  region                   = "${var.region}"
  private_ip_google_access = true
}

resource "random_id" "id" {
  byte_length = 4
}

resource "google_compute_subnetwork" "tf-ci-gke-private" {
  name                     = "${var.network_name}-cluster-${random_id.id.hex}"
  ip_cidr_range            = "10.0.0.0/22"
  network                  = "${google_compute_network.tf-ci.self_link}"
  region                   = "${var.region}"
  private_ip_google_access = true

  secondary_ip_range = [
    {
      range_name    = "${var.network_name}-pods-${random_id.id.hex}"
      ip_cidr_range = "10.40.0.0/14"
    },
    {
      range_name    = "${var.network_name}-services-${random_id.id.hex}"
      ip_cidr_range = "10.0.16.0/20"
    },
  ]
}

resource "google_container_cluster" "tf-ci" {
  name                   = "${var.network_name}"
  private_cluster        = true
  zone                   = "${var.zone}"
  initial_node_count     = 3
  master_ipv4_cidr_block = "172.16.0.0/28"

  master_authorized_networks_config = {
    cidr_blocks = [
      {
        cidr_block   = "0.0.0.0/0"
        display_name = "all"
      },
    ]
  }

  ip_allocation_policy = {
    cluster_secondary_range_name  = "${var.network_name}-pods-${random_id.id.hex}"
    services_secondary_range_name = "${var.network_name}-services-${random_id.id.hex}"
  }

  min_master_version = "${data.google_container_engine_versions.default.latest_node_version}"
  network            = "${google_compute_subnetwork.tf-ci.network}"
  subnetwork         = "${google_compute_subnetwork.tf-ci-gke-private.name}"

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

output cluster_zone {
  value = "${google_container_cluster.tf-ci.zone}"
}

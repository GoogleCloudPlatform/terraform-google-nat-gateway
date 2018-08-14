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

variable gke_master_ip {
  description = "The IP address of the GKE master or a semicolon separated string of multiple IPs"
}

variable gke_node_tag {
  description = "The network tag for the gke nodes"
}

variable region {
  default = "us-central1"
}

variable zone1 {
  default = "us-central1-a"
}

variable zone2 {
  default = "us-central1-b"
}

variable zone3 {
  default = "us-central1-c"
}

variable name {
  default = "gke-ha"
}

variable network {
  default = "default"
}

provider google {
  region = "${var.region}"
}

module "nat-zone-1" {
  source         = "../../"
  name           = "${var.name}-"
  region         = "${var.region}"
  zone           = "${var.zone1}"
  tags           = ["${var.gke_node_tag}"]
  network        = "${var.network}"
  subnetwork     = "${var.network}"
  route_priority = 800
}

module "nat-zone-2" {
  source         = "../../"
  name           = "${var.name}-"
  region         = "${var.region}"
  zone           = "${var.zone2}"
  tags           = ["${var.gke_node_tag}"]
  network        = "${var.network}"
  subnetwork     = "${var.network}"
  route_priority = 800
}

module "nat-zone-3" {
  source         = "../../"
  name           = "${var.name}-"
  region         = "${var.region}"
  zone           = "${var.zone3}"
  tags           = ["${var.gke_node_tag}"]
  network        = "${var.network}"
  subnetwork     = "${var.network}"
  route_priority = 800
}

// Route so that traffic to the master goes through the default gateway.
// This fixes things like kubectl exec and logs
resource "google_compute_route" "gke-master-default-gw" {
  count            = "${var.gke_master_ip == "" ? 0 : length(split(";", var.gke_master_ip))}"
  name             = "${var.gke_node_tag}-master-default-gw-${count.index + 1}"
  dest_range       = "${element(split(";", replace(var.gke_master_ip, "/32", "")), count.index)}"
  network          = "${var.network}"
  next_hop_gateway = "default-internet-gateway"
  tags             = ["${var.gke_node_tag}"]
  priority         = 700
}

output "ip-nat-zone-1" {
  value = "${module.nat-zone-1.external_ip}"
}

output "ip-nat-zone-2" {
  value = "${module.nat-zone-2.external_ip}"
}

output "ip-nat-zone-3" {
  value = "${module.nat-zone-3.external_ip}"
}

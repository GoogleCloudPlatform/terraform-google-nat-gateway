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

variable zone1 {
  default = "us-west1-a"
}

variable zone2 {
  default = "us-west1-b"
}

variable zone3 {
  default = "us-west1-c"
}

provider google {
  region = "${var.region}"
}

variable network_name {
  default = "ha-nat-example"
}

resource "google_compute_network" "default" {
  name                    = "${var.network_name}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "default" {
  name                     = "${var.network_name}"
  ip_cidr_range            = "10.127.0.0/20"
  network                  = "${google_compute_network.default.self_link}"
  region                   = "${var.region}"
  private_ip_google_access = true
}

module "nat-zone-1" {
  source     = "../../"
  name       = "${var.network_name}-"
  region     = "${var.region}"
  zone       = "${var.zone1}"
  network    = "${google_compute_subnetwork.default.name}"
  subnetwork = "${google_compute_subnetwork.default.name}"
}

module "nat-zone-2" {
  source     = "../../"
  name       = "${var.network_name}-"
  region     = "${var.region}"
  zone       = "${var.zone2}"
  network    = "${google_compute_subnetwork.default.name}"
  subnetwork = "${google_compute_subnetwork.default.name}"
}

module "nat-zone-3" {
  source     = "../../"
  name       = "${var.network_name}-"
  region     = "${var.region}"
  zone       = "${var.zone3}"
  network    = "${google_compute_subnetwork.default.name}"
  subnetwork = "${google_compute_subnetwork.default.name}"
}

module "mig1" {
  source             = "GoogleCloudPlatform/managed-instance-group/google"
  version            = "1.1.14"
  region             = "${var.region}"
  zone               = "${var.zone1}"
  name               = "${var.network_name}-mig"
  size               = 2
  access_config      = []
  target_tags        = ["${module.nat-zone-1.routing_tag_regional}"]
  service_port       = 80
  service_port_name  = "none"
  http_health_check  = false
  network            = "${google_compute_subnetwork.default.name}"
  subnetwork         = "${google_compute_subnetwork.default.name}"
  wait_for_instances = true
}

output "nat-host" {
  value = "${module.nat-zone-1.instance}"
}

output "remote-host-uri" {
  value = "${element(module.mig1.instances[0], 0)}"
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

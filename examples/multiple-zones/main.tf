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

provider google {
  region = "${var.region}"
}

variable network_name {
  default = "multi-zone-nat-example"
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

module "mig-zone-1" {
  source             = "GoogleCloudPlatform/managed-instance-group/google"
  version            = "1.1.10"
  region             = "${var.region}"
  zone               = "${var.zone1}"
  name               = "${var.network_name}-mig-1"
  size               = 2
  access_config      = []
  target_tags        = ["${module.nat-zone-1.routing_tag_zonal}"]
  service_port       = 80
  service_port_name  = "http"
  network            = "${google_compute_subnetwork.default.name}"
  subnetwork         = "${google_compute_subnetwork.default.name}"
  wait_for_instances = true
}

module "mig-zone-2" {
  source             = "GoogleCloudPlatform/managed-instance-group/google"
  version            = "1.1.10"
  region             = "${var.region}"
  zone               = "${var.zone2}"
  name               = "${var.network_name}-mig-2"
  size               = 2
  access_config      = []
  target_tags        = ["${module.nat-zone-2.routing_tag_zonal}"]
  service_port       = 80
  service_port_name  = "http"
  network            = "${google_compute_subnetwork.default.name}"
  subnetwork         = "${google_compute_subnetwork.default.name}"
  wait_for_instances = true
}

output "nat-zone-1-host" {
  value = "${module.nat-zone-1.instance}"
}

output "nat-zone-2-host" {
  value = "${module.nat-zone-2.instance}"
}

output "mig-1-host-uri" {
  value = "${element(module.mig-zone-1.instances[0], 0)}"
}

output "mig-2-host-uri" {
  value = "${element(module.mig-zone-2.instances[0], 0)}"
}

output "nat-zone-1-ip" {
  value = "${module.nat-zone-1.external_ip}"
}

output "nat-zone-2-ip" {
  value = "${module.nat-zone-2.external_ip}"
}

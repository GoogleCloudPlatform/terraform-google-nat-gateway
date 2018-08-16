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
  default = "us-central1"
}

variable zone {
  default = "us-central1-c"
}

variable "vm_image" {
  default = "debian-cloud/debian-9"
}

provider google {
  region = "${var.region}"
}

variable network_name {
  default = "squid-nat-example"
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

module "nat" {
  source        = "../../"
  name          = "${var.network_name}-"
  region        = "${var.region}"
  zone          = "${var.zone}"
  network       = "${google_compute_subnetwork.default.name}"
  subnetwork    = "${google_compute_subnetwork.default.name}"
  squid_enabled = "true"
}

resource "google_compute_instance" "vm" {
  name                      = "${var.network_name}-vm"
  zone                      = "${var.zone}"
  tags                      = ["${var.network_name}-ssh", "${var.network_name}-squid"]
  machine_type              = "f1-micro"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "${var.vm_image}"
    }
  }

  network_interface {
    subnetwork    = "${google_compute_subnetwork.default.name}"
    access_config = []
  }
}

resource "google_compute_firewall" "vm-ssh" {
  name    = "${var.network_name}-ssh"
  network = "${google_compute_subnetwork.default.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.network_name}-ssh"]
}

// Since we aren't using the NAT on the test VM, add separate firewall rule for the squid proxy.
resource "google_compute_firewall" "nat-squid" {
  name    = "${var.network_name}-squid"
  network = "${google_compute_subnetwork.default.name}"

  allow {
    protocol = "tcp"
    ports    = ["3128"]
  }

  source_tags = ["${var.network_name}-squid"]
  target_tags = ["inst-${module.nat.routing_tag_zonal}"]
}

output "nat-host" {
  value = "${module.nat.instance}"
}

output "nat-ip" {
  value = "${module.nat.external_ip}"
}

output "vm-host" {
  value = "${google_compute_instance.vm.self_link}"
}

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

variable zone {
  default = "us-west1-b"
}

variable staging_network_name {
  default = "staging"
}

variable staging_mig_name {
  default = "staging"
}

variable production_network_name {
  default = "production"
}

variable production_mig_name {
  default = "production"
}

provider google {
  region = "${var.region}"
}

data "template_file" "startup-script" {
  template = "${file("${format("%s/gceme.sh.tpl", path.module)}")}"

  vars {
    PROXY_PATH = ""
  }
}

// Staging resources

resource "google_compute_network" "staging" {
  name                    = "${var.staging_network_name}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "staging" {
  name          = "${var.staging_network_name}"
  ip_cidr_range = "10.137.0.0/20"
  network       = "${google_compute_network.staging.self_link}"
  region        = "${var.region}"
}

module "staging-mig1" {
  source             = "github.com/GoogleCloudPlatform/terraform-google-managed-instance-group"
  region             = "${var.region}"
  zone               = "${var.zone}"
  name               = "${var.staging_mig_name}"
  network            = "${google_compute_subnetwork.staging.network}"
  subnetwork         = "${google_compute_subnetwork.staging.name}"
  size               = 2
  access_config      = []
  target_tags        = ["allow-staging", "${var.staging_network_name}-nat-${var.region}"]
  service_port       = 80
  service_port_name  = "http"
  wait_for_instances = true
  startup_script     = "${data.template_file.startup-script.rendered}"
  depends_id         = "${module.staging-nat-gateway.depends_id}"
}

module "staging-nat-gateway" {
  // source  = "github.com/GoogleCloudPlatform/terraform-google-nat-gateway"
  source     = "../../"
  name       = "${var.staging_network_name}-"
  region     = "${var.region}"
  network    = "${google_compute_network.staging.name}"
  subnetwork = "${google_compute_subnetwork.staging.name}"
}

// Production resources

resource "google_compute_network" "production" {
  name                    = "${var.production_network_name}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "production" {
  name          = "${var.production_network_name}"
  ip_cidr_range = "10.137.0.0/20"
  network       = "${google_compute_network.production.self_link}"
  region        = "${var.region}"
}

module "production-mig1" {
  source             = "github.com/GoogleCloudPlatform/terraform-google-managed-instance-group"
  region             = "${var.region}"
  zone               = "${var.zone}"
  name               = "${var.production_mig_name}"
  network            = "${google_compute_subnetwork.production.network}"
  subnetwork         = "${google_compute_subnetwork.production.name}"
  size               = 2
  access_config      = []
  target_tags        = ["allow-production", "${var.production_network_name}-nat-${var.region}"]
  service_port       = 80
  service_port_name  = "http"
  wait_for_instances = true
  startup_script     = "${data.template_file.startup-script.rendered}"
  depends_id         = "${module.production-nat-gateway.depends_id}"
}

module "production-nat-gateway" {
  // source  = "github.com/GoogleCloudPlatform/terraform-google-nat-gateway"
  source     = "../../"
  name       = "${var.production_network_name}-"
  region     = "${var.region}"
  network    = "${google_compute_network.production.name}"
  subnetwork = "${google_compute_subnetwork.production.name}"
}

module "gce-lb-http" {
  source            = "github.com/GoogleCloudPlatform/terraform-google-lb-http"
  name              = "${var.production_network_name}-lb"
  target_tags       = ["allow-staging", "allow-production"]
  firewall_networks = ["${google_compute_network.staging.name}", "${google_compute_network.production.name}"]

  backends = {
    "0" = [
      {
        group = "${module.staging-mig1.instance_group}"
      },
      {
        group = "${module.production-mig1.instance_group}"
      },
    ]
  }

  backend_params = [
    // health check path, port name, port number, timeout seconds.
    "/,http,80,10",
  ]
}

output "ip-lb" {
  value = "${module.gce-lb-http.external_ip}"
}

output "ip-nat-staging" {
  value = "${module.staging-nat-gateway.external_ip}"
}

output "ip-nat-production" {
  value = "${module.production-nat-gateway.external_ip}"
}

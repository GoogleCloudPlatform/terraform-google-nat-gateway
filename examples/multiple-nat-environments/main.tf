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
  name                    = "staging"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "staging-us-west1" {
  name          = "staging-us-west1"
  ip_cidr_range = "10.138.0.0/20"
  network       = "${google_compute_network.staging.self_link}"
  region        = "us-west1"
}

module "staging-mig1" {
  source            = "github.com/GoogleCloudPlatform/terraform-google-managed-instance-group"
  region            = "us-west1"
  zone              = "us-west1-b"
  name              = "staging"
  network           = "${google_compute_subnetwork.staging-us-west1.network}"
  subnetwork        = "${google_compute_subnetwork.staging-us-west1.name}"
  size              = 2
  access_config     = []
  target_tags       = ["allow-staging", "staging-nat-us-west1"]
  service_port      = 80
  service_port_name = "http"
  startup_script    = "${data.template_file.startup-script.rendered}"
  depends_id        = "${module.staging-nat-gateway.depends_id}"
}

module "staging-nat-gateway" {
  // source  = "github.com/GoogleCloudPlatform/terraform-google-nat-gateway"
  source     = "../../"
  name       = "staging-"
  region     = "us-west1"
  network    = "${google_compute_network.staging.name}"
  subnetwork = "${google_compute_subnetwork.staging-us-west1.name}"
}

// Production resources

resource "google_compute_network" "production" {
  name                    = "production"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "production-us-west1" {
  name          = "production-us-west1"
  ip_cidr_range = "10.138.0.0/20"
  network       = "${google_compute_network.production.self_link}"
  region        = "us-west1"
}

module "production-mig1" {
  source            = "github.com/GoogleCloudPlatform/terraform-google-managed-instance-group"
  region            = "us-west1"
  zone              = "us-west1-b"
  name              = "production"
  network           = "${google_compute_subnetwork.production-us-west1.network}"
  subnetwork        = "${google_compute_subnetwork.production-us-west1.name}"
  size              = 2
  access_config     = []
  target_tags       = ["allow-production", "production-nat-us-west1"]
  service_port      = 80
  service_port_name = "http"
  startup_script    = "${data.template_file.startup-script.rendered}"
  depends_id        = "${module.production-nat-gateway.depends_id}"
}

module "production-nat-gateway" {
  // source  = "github.com/GoogleCloudPlatform/terraform-google-nat-gateway"
  source     = "../../"
  name       = "production-"
  region     = "us-west1"
  network    = "${google_compute_network.production.name}"
  subnetwork = "${google_compute_subnetwork.production-us-west1.name}"
}

module "gce-lb-http" {
  source            = "github.com/GoogleCloudPlatform/terraform-google-lb-http"
  name              = "multi-nat-http-lb"
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

output "ip-nat-staging" {
  value = "${module.staging-nat-gateway.external_ip}"
}

output "ip-nat-production" {
  value = "${module.production-nat-gateway.external_ip}"
}
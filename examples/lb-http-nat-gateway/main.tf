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

variable network_name {
  default = "lb-nat-example"
}

provider google {
  region = "${var.region}"
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

data "template_file" "group1-startup-script" {
  template = "${file("${format("%s/gceme.sh.tpl", path.module)}")}"

  vars {
    PROXY_PATH = ""
  }
}

module "mig1" {
  source             = "github.com/GoogleCloudPlatform/terraform-google-managed-instance-group"
  region             = "${var.region}"
  zone               = "${var.zone}"
  name               = "${var.network_name}-mig"
  size               = 2
  access_config      = []
  target_tags        = ["${var.network_name}-mig", "nat-${var.region}"]
  service_port       = 80
  service_port_name  = "http"
  wait_for_instances = true
  startup_script     = "${data.template_file.group1-startup-script.rendered}"
  depends_id         = "${module.nat-gateway.depends_id}"
  network            = "${google_compute_subnetwork.default.name}"
  subnetwork         = "${google_compute_subnetwork.default.name}"
}

module "nat-gateway" {
  // source  = "github.com/GoogleCloudPlatform/terraform-google-nat-gateway"
  source     = "../../"
  region     = "${var.region}"
  zone       = "${var.zone}"
  network    = "${google_compute_subnetwork.default.name}"
  subnetwork = "${google_compute_subnetwork.default.name}"
}

module "gce-lb-http" {
  source            = "github.com/GoogleCloudPlatform/terraform-google-lb-http"
  name              = "${var.network_name}-lb"
  target_tags       = ["${var.network_name}-mig"]
  firewall_networks = ["${google_compute_subnetwork.default.name}"]

  backends = {
    "0" = [
      {
        group = "${module.mig1.instance_group}"
      },
    ]
  }

  backend_params = [
    // health check path, port name, port number, timeout seconds.
    "/,http,80,10",
  ]
}

output "ip-nat-gateway" {
  value = "${module.nat-gateway.external_ip}"
}

output "ip-lb" {
  value = "${module.gce-lb-http.external_ip}"
}

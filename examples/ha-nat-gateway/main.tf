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

module "nat-us-west1-a" {
  source  = "../../"
  region  = "us-west1"
  zone    = "us-west1-a"
  network = "default"
}

module "nat-us-west1-b" {
  source  = "../../"
  region  = "us-west1"
  zone    = "us-west1-b"
  network = "default"
}

module "nat-us-west1-c" {
  source  = "../../"
  region  = "us-west1"
  zone    = "us-west1-c"
  network = "default"
}

module "mig1" {
  source            = "github.com/GoogleCloudPlatform/terraform-google-managed-instance-group"
  region            = "us-west1"
  zone              = "us-west1-b"
  name              = "group1"
  size              = 2
  access_config     = []
  target_tags       = ["nat-us-west1"]
  service_port      = 80
  service_port_name = "http"
}
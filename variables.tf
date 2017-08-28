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
 
variable network {
  description = "The network to deploy to"
  default     = "default"
}

variable subnetwork {
  description = "The subnetwork to deploy to"
  default     = "default"
}

variable region {
  description = "The region to create the nat gateway instance in."
}

variable zone {
  description = "Override the zone used in the `region_params` map for the region."
  default     = ""
}

variable machine_type {
  description = "The machine type for the NAT gateway instance"
  default     = "n1-standard-1"
}

variable ip {
  description = "Override the IP used in the `region_params` map for the region."
  default     = ""
}

variable squid_enabled {
  description = "Enable squid3 proxy on port 3128."
  default     = "false"
}

variable squid_config {
  description = "The squid config file to use. If not specifed the module file config/squid.conf will be used."
  default     = ""
}

variable region_params {
  description = "Map of default zones and IPs for each region. Can be overridden using the `zone` and `ip` variables."
  type        = "map"

  default = {
    us-west1 {
      zone = "us-west1-b"
      ip   = "10.138.1.1"
    }

    us-central1 {
      zone = "us-central1-f"
      ip   = "10.128.1.1"
    }

    us-east1 {
      zone = "us-east1-b"
      ip   = "10.142.1.1"
    }

    us-east4 {
      zone = "us-east4-b"
      ip   = "10.150.1.1"
    }

    europe-west1 {
      zone = "europe-west1-b"
      ip   = "10.132.1.1"
    }

    europe-west2 {
      zone = "europe-west2-b"
      ip   = "10.154.1.1"
    }

    europe-west3 {
      zone = "europe-west3-b"
      ip   = "10.156.1.1"
    }

    asia-southeast1 {
      zone = "asia-southeast1-b"
      ip   = "10.148.1.1"
    }

    asia-east1 {
      zone = "asia-east1-b"
      ip   = "10.142.1.1"
    }

    asia-northeast1 {
      zone = "asia-northeast1-b"
      ip   = "10.146.1.1"
    }

    austrailia-southeast1 {
      zone = "austrailia-southeast1-b"
      ip   = "10.152.1.1"
    }
  }
}

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

output depends_id {
  description = "Value that can be used for intra-module dependency creation."
  value       = "${module.nat-gateway.depends_id}"
}

output gateway_ip {
  description = "The internal IP address of the NAT gateway instance."
  value       = "${module.nat-gateway.network_ip}"
}

output external_ip {
  description = "The external IP address of the NAT gateway instance."
  value       = "${google_compute_address.default.address}"
}

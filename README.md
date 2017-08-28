# NAT Gateway Terraform Module

Modular NAT Gateway on Google Compute Engine for Terraform.

## Usage

```ruby
module "nat" {
  source  = "github.com/GoogleCloudPlatform/terraform-google-nat-gateway"
  region  = "us-central1"
  network = "default"
}
```

Add the `nat-REGION` tag to your instances without external IPs to route outbound traffic through the nat gateway.

### Input variables

- `region` (required): The region to create the nat gateway instance in.
- `zone` (optional): Override the zone used in the `region_params` map for the region.
- `network` (optional): The network to deploy to.
- `subnetwork` (optional): The subnetwork to deploy to.
- `tags` (optional): List of additional compute instance network tags to apply route to. Default is `["nat-REGION"]`.
- `route_priority` (optional): The priority for the Compute Engine Route. Default is `800`.
- `ip` (optional): Override the IP used in the `region_params` map for the region.
- `squid_enabled` (optional): Enable squid3 proxy on port 3128. Default is `false`
- `squid_config` (optional): The squid config file to use. If not specifed the module file config/squid.conf will be used.

### Output variables 

- `depends_id`: Value that can be used for intra-module dependency creation.
- `gateway_ip`: The internal IP address of the NAT gateway instance.
- `external_ip`: The external IP address of the NAT gateway instance.

## Resources created

- [`module.nat-gateway`](https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group): The NAT gateway managed instance group module.
- [`google_compute_route.nat-gateway`](https://www.terraform.io/docs/providers/google/r/compute_route.html): The route rule for the NAT gatway.
- [`google_compute_firewall.nat-gateway`](https://www.terraform.io/docs/providers/google/r/compute_firewall.html): Firewall rule to allow traffic from the nat-REGION tagged instances.
- [`google_compute_address.default`](https://www.terraform.io/docs/providers/google/r/compute_address.html): Static IP reservation for the NAT gateway instance.
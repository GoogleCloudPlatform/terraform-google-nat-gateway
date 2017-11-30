# NAT Gateway Terraform Module

Modular NAT Gateway on Google Compute Engine for Terraform.

## Usage

```ruby
module "nat" {
  source     = "GoogleCloudPlatform/nat-gateway/google"
  region     = "us-central1"
  network    = "default"
  subnetwork = "default"
}
```

Add the `nat-REGION-ZONE` tag to your instances without external IPs to route outbound traffic through the nat gateway.

## Resources created

- [`module.nat-gateway`](https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group): The NAT gateway managed instance group module.
- [`google_compute_route.nat-gateway`](https://www.terraform.io/docs/providers/google/r/compute_route.html): The route rule for the NAT gatway.
- [`google_compute_firewall.nat-gateway`](https://www.terraform.io/docs/providers/google/r/compute_firewall.html): Firewall rule to allow traffic from the nat-REGION tagged instances.
- [`google_compute_address.default`](https://www.terraform.io/docs/providers/google/r/compute_address.html): Static IP reservation for the NAT gateway instance.

# NAT Gateway Terraform Module

## Deprecation Notice
**NOTE: This module is no longer maintained.** Please use [Cloud NAT](https://github.com/terraform-google-modules/terraform-google-cloud-nat) instead. For information on how to migrate to the Cloud NAT module, refer to the [migration guide](./docs/cloud-nat-migration-guide.md).
        
## Usage

```ruby
module "nat" {
  source     = "GoogleCloudPlatform/nat-gateway/google"
  region     = "us-central1"
  network    = "default"
  subnetwork = "default"
}
```

And add the tag `${module.nat.routing_tag_regional}` to your instances without external IPs to route outbound traffic through the nat gateway.

## Usage

```ruby
module "mig" {
  source      = "GoogleCloudPlatform/managed-instance-group/google"
  version     = "1.1.14"
  region      = "us-central1"
  zone        = "us-central1-a"
  name        = "testnat"
  target_tags = ["${module.nat.routing_tag_regional}"]
  network     = "default"
  subnetwork  = "default"
}
```


## Resources created

- [`module.nat-gateway`](https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group): The NAT gateway managed instance group module.
- [`google_compute_route.nat-gateway`](https://www.terraform.io/docs/providers/google/r/compute_route.html): The route rule for the NAT gatway.
- [`google_compute_firewall.nat-gateway`](https://www.terraform.io/docs/providers/google/r/compute_firewall.html): Firewall rule to allow traffic from the nat-REGION tagged instances.
- [`google_compute_address.default`](https://www.terraform.io/docs/providers/google/r/compute_address.html): Static IP reservation for the NAT gateway instance.

# NAT Gateway Terraform Module

Modular NAT Gateway on Google Compute Engine for Terraform.

<a href="https://concourse-tf.gcp.solutions/teams/main/pipelines/tf-nat-gw-regression" target="_blank">
<img src="https://concourse-tf.gcp.solutions/api/v1/teams/main/pipelines/tf-nat-gw-regression/badge" /></a>
        
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
  source      = "github.com/GoogleCloudPlatform/terraform-google-managed-instance-group"
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

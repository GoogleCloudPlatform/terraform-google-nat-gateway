# NAT Gateway to Cloud NAT Migration Guide
This guide explains how to migrate from an instance-based NAT gateway to the managed [Cloud NAT](https://cloud.google.com/nat/docs/overview) resource. For more information see the following [documentation](https://cloud.google.com/vpc/docs/special-configurations#migrate-nat).

## Configure a Cloud NAT
In the same region your instance-based NAT gateway is located, configure a Cloud NAT resource.

### Using Console or API
Use [these instructions](https://cloud.google.com/nat/docs/using-nat) to configure a Cloud NAT in the same region as your instance-based NAT gateway.

### Using [Cloud NAT Terraform Module](https://github.com/terraform-google-modules/terraform-google-cloud-nat)
_The instructions below are intended for Terraform 0.12. We recommend [upgrading your resources](https://www.terraform.io/upgrade-guides/0-12.html) to Terraform 0.12, but if you need a Terraform 0.11.x-compatible version of Cloud NAT, use version [0.1.0](https://registry.terraform.io/modules/terraform-google-modules/cloud-nat/google/0.1.0) of [terraform-google-cloud-nat](https://github.com/terraform-google-modules/terraform-google-cloud-nat)._

Create a Cloud NAT resource in your region. If you do not have a Cloud Router, create one using the `google_compute_router` resource.
```hcl
resource "google_compute_router" "router" {
  name    = "load-balancer-module-router"
  region  = var.region
  network = var.network
}

module "cloud_nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.0.0"
  project_id = var.project_id
  region     = var.region
  name       = "load-balancer-module-nat"
  router     = google_compute_router.router.name
}
```

## Remove static routes
Delete the [static routes](https://cloud.google.com/vpc/docs/using-routes#deletingaroute) that are sending traffic to the instanced-based NAT gateway. 

* If created via NAT gateway module, routes will be named `[prefix]nat-[zone]`
* If created via console or API, routes [may be called](https://cloud.google.com/vpc/docs/special-configurations#natgateway): `no-ip-internet-route`, `natroute1`, `natroute2`, `natroute3`

Once removed, confirm that traffic is flowing through Cloud NAT from an instance in your network.

## Remove NAT gateway
Delete your NAT gateway instance(s).

* If created via NAT gateway module, remove the instance of the module from Terraform and re-apply
* If created via console or API, delete your instance-based NAT gateways

## Note for users of squid proxy functionality in NAT gateway
Cloud NAT does not support squid or network proxy functionality. To use a squid proxy, see the following [documentation](https://cloud.google.com/vpc/docs/special-configurations#proxyvm).
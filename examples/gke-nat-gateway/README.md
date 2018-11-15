# NAT Gateway for GKE Nodes

[![button](//gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/open?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/terraform-google-nat-gateway&cloudshell_image=gcr.io/graphite-cloud-shell-images/terraform:latest&open_in_editor=examples/gke-nat-gateway/main.tf&cloudshell_tutorial=./examples/gke-nat-gateway/README.md)

This example creates a NAT Gateway and Compute Engine Network Routes to route outbound traffic from an existing GKE cluster through the NAT Gateway instance.

**Figure 1.** *diagram of Google Cloud resources*

![architecture diagram](https://raw.githubusercontent.com/GoogleCloudPlatform/terraform-google-nat-gateway/master/examples/gke-nat-gateway/diagram.png)

> Note: This example only deploys a single-node NAT gateway instance and is not intended for production use. See the [ha-natgateway](../ha-nat-gateway) example for a highly available option.

## Set up the Environment

1. Set the project, replace YOUR_PROJECT with your project ID:

```bash
PROJECT=YOUR_PROJECT
```

```bash
gcloud config set project ${PROJECT};
```

2. Configure the environment for Terraform:

```bash
([[ $CLOUD_SHELL ]] || gcloud auth application-default login);
export GOOGLE_PROJECT=$(gcloud config get-value project);
```

3. This example assumes you have an existing Container Engine cluster. If not, create a cluster:

```bash
gcloud container clusters create dev-nat --zone=us-central1-b;
```

## Change to the example directory

```bash
[[ $(basename $PWD) == gke-nat-gateway ]] || cd examples/gke-nat-gateway;
```

### Get Master IP and Node Tags

Record the target cluster name, region and zone:

```bash
export CLUSTER_NAME=dev-nat;
export REGION=us-central1;
export ZONE=us-central1-b;
export NETWORK=default;
export SUBNETWORK=default;
```

Create a `terraform.tfvars` file with the the region, zone, master IP, and the node pool nework tag name to the tfvars file:

```bash
export NODE_TAG=$(gcloud compute instance-templates describe $(gcloud compute instance-templates list --filter=name~gke-${CLUSTER_NAME:0:20} --limit=1 --uri) --format='get(properties.tags.items[0])');
export MASTER_IP=$(gcloud compute firewall-rules describe ${NODE_TAG/-node/-ssh} --format='value(sourceRanges)');

./make_vars.sh;

cat terraform.tfvars;
```

## Run Terraform

```bash
terraform init && terraform apply
```

## Verify NAT Gateway Routing

Show the external IP address that the cluster node is using by running a Kubernetes pod that uses curl:

```bash
kubectl run example -i -t --rm --restart=Never --image centos:7 -- curl -s http://ipinfo.io/ip
```

The IP address shown in the pod output should match the value of the NAT Gateway `external_ip`. Get the external IP of the NAT Gateway by running the command below:

```bash
terraform output
```

## Caveats

1. The web console SSH will no longer work, you have to jump through the NAT gateway machine to SSH into a GKE node:

```bash
eval ssh-agent $SHELL;
```

```bash
gcloud compute config-ssh
```

```bash
ssh-add ~/.ssh/google_compute_engine;
CLUSTER_NAME=dev-nat;
REGION=us-central1;
gcloud compute ssh $(gcloud compute instances list --filter=name~nat-gateway-${REGION} --uri) --ssh-flag="-A" -- ssh $(gcloud compute instances list --filter=name~gke-${CLUSTER_NAME}- --limit=1 --format='value(name)') -o StrictHostKeyChecking=no;
```

## Cleanup

1. Remove all resources created by terraform:

```bash
terraform destroy
```

2. Delete Kubernetes Engine cluster:

```bash
gcloud container clusters delete dev-nat --zone us-central1-b
```
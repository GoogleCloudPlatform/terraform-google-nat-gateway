# Highly Available NAT Gateway Example

This example creates a NAT gateway in 3 Compute Engine zones within the same region. Traffic is balanced between the instances using equal cost based routing with equal route priorities to the same instance tag.

**Figure 1.** *diagram of Google Cloud resources*

![architecture diagram](./diagram.png)

## Setup Environment

```
gcloud auth application-default login
export GOOGLE_PROJECT=$(gcloud config get-value project)
```

## Run Terraform

```
terraform init
terraform plan
terraform apply
```

SSH into the instance by hopping through one of the NAT gateway instances.

```
gcloud compute ssh $(gcloud compute instances list --filter=name~nat-gateway- --limit=1 --uri) --ssh-flag="-A" -- ssh $(gcloud compute instances list --filter=name~group1- --limit=1 --format='value(name)')
```

Check the external IP of the instance:

```
curl http://ipinfo.io/ip
```

Repeat the command above a few times and notice that it cycles between the external IP of the NAT gateway instances.

## Cleanup

Remove all resources created by terraform:

```
terraform destroy
```
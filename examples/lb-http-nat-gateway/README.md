# Global HTTP Example to GCE instances with NAT Gateway

This example creates a global HTTP forwarding rule to an instance group without external IPs. The instances access the internet via a NAT gateway.

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

Open URL of load balancer in browser:

```
EXTERNAL_IP=$(terraform output -module gce-lb-http | grep external_ip | cut -d = -f2 | xargs echo -n)
(until curl -sf -o /dev/null http://${EXTERNAL_IP}; do echo "Waiting for Load Balancer... "; sleep 5 ; done) && open http://${EXTERNAL_IP}
```

You should see the details of instances from `group1`. The `External IP` field should match the external IP of the NAT gateway instnace:

```
terraform output -module nat-gateway
```

## Cleanup

Remove all resources created by terraform:

```
terraform destroy
```
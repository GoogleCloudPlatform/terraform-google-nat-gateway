# NAT Gateway Module Disable Example

This example creates a NAT gateway and demonstrates how to disable it using the input variable.

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

Verify egress traffic is routed through NAT gateway:

```
./test.sh nat
```

## Disable the module

```
cat > terraform.tfvars <<EOF
module_enabled = false
EOF
```

Run Terraform:

```
terraform apply
```

Verify egress traffic is passed directly from the VM:

```
./test.sh direct
```

## Cleanup

Remove all resources created by terraform:

```
terraform destroy
```

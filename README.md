# Overview

Aim of this study is to build classic Two-Tier application using Google Cloud Engine using Terraform.

This code will create Bastion (for SSH access and for NAT purpose) and Frontend instances, which will be publicly available. Additionally, there will be an private API service deployed.

Frontend = nginx-as-rev-proxy-to-api
API = apache2-with-default-web-page

## Internal DNS names
* demo-vpc-api
* demo-vpc-bastion
* demo-vpc-frontend

# Terraform variables
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| bastion_ssh_access | CIDRs to limit Bastion access to. | string | `<list>` | no |
| credentials | Path to JSON file with credentials. | string | - | yes |
| gce_ssh_pub_key_file | Path to your id_rsa.pub file. | string | `~/.ssh/id_rsa.pub` | no |
| gce_ssh_user | Username to use for SSH access. | string | `admin` | no |
| project | Project ID. | string | - | yes |
| region | Region to use, ie. europe-west-2. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| bastion_ssh_cmd | Command for SSH connection. |
| bastion_ssh_gcloud_cmd | Command for SSH conneciton using gcloud. |
| frontend_address | URL to open. You should see debian-apache2 default page. |

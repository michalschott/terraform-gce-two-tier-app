# Overview

Aim of this study is to build classic Two-Tier application (HA) using Google Cloud Engine using Terraform.

This code will create:
* bastion host (for SSH access and for NAT purpose)
* two frontend instances as a backend for public loadbalancer
* two api instances as a backend for internal loadbalancer

# Terraform variables
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| bastion_ssh_access | CIDRs to limit Bastion access to. | string | `<list>` | no |
| credentials | Path to JSON file with credentials. | string | - | yes |
| gce_ssh_pub_key_file | Path to your id_rsa.pub file. | string | `~/.ssh/id_rsa.pub` | no |
| gce_ssh_user | Username to use for SSH access. | string | `admin` | no |
| lb_ip_api | IP address for API internal LB. | string | `192.168.3.145` | no |
| networks | Networks, CIDR format. | string | `<map>` | no |
| project | Project ID. | string | - | yes |
| region | Region to use, ie. europe-west-2. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| bastion_ssh_cmd | Command for SSH connection. |
| bastion_ssh_gcloud_cmd | Command for SSH conneciton using gcloud. |
| frontend_address | URL to open. You should see debian-apache2 default page. |

# How to run?
```
terraform apply

# ssh to bastion
$(terraform output bastion_ssh_cmd)

# mac only
open $(terraform output frontend_address)
```

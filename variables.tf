variable credentials {
  description = "Path to JSON file with credentials."
}

variable project {
  description = "Project ID."
}

variable region {
  description = "Region to use, ie. europe-west-2."
}

variable bastion_ssh_access {
  default     = ["0.0.0.0/0"]
  description = "CIDRs to limit Bastion access to."
}

variable gce_ssh_user {
  description = "Username to use for SSH access."
  default     = "admin"
}

variable gce_ssh_pub_key_file {
  description = "Path to your id_rsa.pub file."
  default     = "~/.ssh/id_rsa.pub"
}

variable networks {
  description = "Networks, CIDR format."

  default = {
    "api"      = "192.168.3.0/24"
    "bastion"  = "192.168.1.0/24"
    "frontend" = "192.168.2.0/24"
  }
}

variable lb_ip_api {
  description = "IP address for API internal LB."
  default     = "192.168.3.145"
}

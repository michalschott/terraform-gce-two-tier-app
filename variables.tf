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

resource "google_compute_network" "demo-vpc" {
  name                    = "demo-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_route" "demo-vpc-api-nat-default" {
  name                   = "demo-vpc-api-nat-default"
  dest_range             = "0.0.0.0/0"
  network                = "${google_compute_network.demo-vpc.name}"
  next_hop_instance      = "${google_compute_instance.demo-vpc-bastion.self_link}"
  next_hop_instance_zone = "${var.region}-a"
  priority               = 800
  tags                   = ["api"]
}

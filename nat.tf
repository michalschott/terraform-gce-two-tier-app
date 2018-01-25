resource "google_compute_route" "demo-vpc-nat" {
  name                   = "demo-vpc-nat"
  dest_range             = "0.0.0.0/0"
  network                = "${google_compute_network.demo-vpc.name}"
  next_hop_instance      = "${google_compute_instance.demo-vpc-bastion.self_link}"
  next_hop_instance_zone = "${var.region}-a"
  priority               = 800
  tags                   = ["api", "frontend"]
}

resource "google_compute_firewall" "demo-vpc-nat" {
  name        = "demo-vpc-nat"
  network     = "${google_compute_network.demo-vpc.name}"
  source_tags = ["api", "frontend"]
  target_tags = ["bastion"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}

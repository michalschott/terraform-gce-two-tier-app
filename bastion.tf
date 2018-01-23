resource "google_compute_subnetwork" "demo-vpc-bastion" {
  name          = "demo-vpc-europe-west2-bastion"
  ip_cidr_range = "192.168.1.0/24"
  network       = "${google_compute_network.demo-vpc.self_link}"
  region        = "${var.region}"
}

resource "google_compute_address" "demo-vpc-bastion" {
  name   = "demo-vpc-bastion"
  region = "${var.region}"
}

resource "google_compute_firewall" "demo-vpc-bastion-ssh" {
  name          = "demo-vpc-bastion-ssh"
  network       = "${google_compute_network.demo-vpc.name}"
  source_ranges = ["${var.bastion_ssh_access}"]
  target_tags   = ["bastion"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "demo-vpc-bastion-nat" {
  name        = "demo-vpc-bastion-nat"
  network     = "${google_compute_network.demo-vpc.name}"
  source_tags = ["api"]

  #source_ranges = ["192.168.0.0/16"]

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

resource "google_compute_instance" "demo-vpc-bastion" {
  name           = "demo-vpc-bastion"
  machine_type   = "f1-micro"
  zone           = "${var.region}-a"
  can_ip_forward = true

  tags = ["bastion"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.demo-vpc-bastion.self_link}"

    access_config {
      nat_ip = "${google_compute_address.demo-vpc-bastion.address}"
    }
  }

  metadata {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = <<EOF
echo 1 > /proc/sys/net/ipv4/ip_forward && \
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
EOF
}

output bastion_ssh_cmd {
  value       = "ssh ${var.gce_ssh_user}@${google_compute_address.demo-vpc-bastion.address}"
  description = "Command for SSH connection."
}

output bastion_ssh_gcloud_cmd {
  value       = "gcloud compute --project \"${var.project}\" ssh --zone \"${var.region}-a\" \"demo-vpc-bastion\""
  description = "Command for SSH conneciton using gcloud."
}

resource "google_compute_subnetwork" "demo-vpc-bastion" {
  name          = "demo-vpc-europe-west2-bastion"
  ip_cidr_range = "${lookup(var.networks, "bastion")}"
  network       = "${google_compute_network.demo-vpc.self_link}"
  region        = "${var.region}"
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
      nat_ip = ""
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
  value       = "ssh ${var.gce_ssh_user}@${google_compute_instance.demo-vpc-bastion.network_interface.0.access_config.0.assigned_nat_ip}"
  description = "Command for SSH connection."
}

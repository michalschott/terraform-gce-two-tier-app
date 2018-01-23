resource "google_compute_subnetwork" "demo-vpc-api" {
  name          = "demo-vpc-europe-west2-api"
  ip_cidr_range = "192.168.3.0/24"
  network       = "${google_compute_network.demo-vpc.self_link}"
  region        = "${var.region}"
}

resource "google_compute_firewall" "demo-vpc-api-ssh" {
  name        = "demo-vpc-api-ssh"
  network     = "${google_compute_network.demo-vpc.name}"
  source_tags = ["bastion"]
  target_tags = ["api"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "demo-vpc-api-8080" {
  name        = "demo-vpc-api-8080"
  network     = "${google_compute_network.demo-vpc.name}"
  source_tags = ["frontend"]
  target_tags = ["api"]

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
}

resource "google_compute_instance" "demo-vpc-api" {
  name         = "demo-vpc-api"
  machine_type = "f1-micro"
  zone         = "${var.region}-a"
  tags         = ["api"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.demo-vpc-api.self_link}"
  }

  metadata {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = <<EOF
apt-get install -y apache2 && \
sed -i -e 's/80/8080/g' /etc/apache2/ports.conf && \
sed -i -e 's/80/8080/g' /etc/apache2/sites-available/000-default.conf && \
systemctl restart apache2
EOF

  depends_on = ["google_compute_instance.demo-vpc-bastion", "google_compute_firewall.demo-vpc-bastion-nat"]
}

resource "google_compute_subnetwork" "demo-vpc-api" {
  name          = "demo-vpc-europe-west2-api"
  ip_cidr_range = "${lookup(var.networks, "api")}"
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

resource "google_compute_firewall" "demo-vpc-api-8080-health-check" {
  name          = "demo-vpc-api-8080-health-check"
  network       = "${google_compute_network.demo-vpc.name}"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["api"]

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
}

resource "google_compute_instance_template" "demo-vpc-api" {
  name_prefix  = "demo-vpc-api-"
  machine_type = "f1-micro"
  region       = "${var.region}"
  tags         = ["api"]

  disk {
    source_image = "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "demo-vpc-api" {
  name               = "demo-vpc-api"
  zone               = "${var.region}-a"
  base_instance_name = "demo-vpc-api"
  instance_template  = "${google_compute_instance_template.demo-vpc-api.self_link}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_forwarding_rule" "demo-vpc-api" {
  name                  = "demo-vpc-api"
  load_balancing_scheme = "INTERNAL"
  ports                 = ["8080"]
  network               = "${google_compute_network.demo-vpc.self_link}"
  subnetwork            = "${google_compute_subnetwork.demo-vpc-api.self_link}"
  backend_service       = "${google_compute_region_backend_service.demo-vpc-api.self_link}"
  ip_address            = "${var.lb_ip_api}"
}

resource "google_compute_region_backend_service" "demo-vpc-api" {
  name   = "demo-vpc-api"
  region = "${var.region}"

  health_checks = [
    "${google_compute_health_check.demo-vpc-api.self_link}",
  ]

  backend {
    group = "${google_compute_instance_group_manager.demo-vpc-api.instance_group}"
  }
}

resource "google_compute_autoscaler" "demo-vpc-api" {
  name   = "demo-vpc-api"
  zone   = "${var.region}-a"
  target = "${google_compute_instance_group_manager.demo-vpc-api.self_link}"

  autoscaling_policy = {
    max_replicas = 2
    min_replicas = 2

    cpu_utilization {
      target = 0.6
    }
  }
}

resource "google_compute_health_check" "demo-vpc-api" {
  name                = "demo-vpc-api"
  timeout_sec         = 5
  check_interval_sec  = 5
  unhealthy_threshold = 2

  tcp_health_check {
    port = 8080
  }
}

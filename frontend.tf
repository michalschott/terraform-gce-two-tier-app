resource "google_compute_subnetwork" "demo-vpc-frontend" {
  name          = "demo-vpc-europe-west2-frontend"
  ip_cidr_range = "${lookup(var.networks, "frontend")}"
  network       = "${google_compute_network.demo-vpc.self_link}"
  region        = "${var.region}"
}

resource "google_compute_address" "demo-vpc-frontend" {
  name   = "demo-vpc-frontend"
  region = "${var.region}"
}

resource "google_compute_firewall" "demo-vpc-frontend-ssh" {
  name        = "demo-vpc-frontend-ssh"
  network     = "${google_compute_network.demo-vpc.name}"
  source_tags = ["bastion"]
  target_tags = ["frontend"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "demo-vpc-frontend-http" {
  name        = "demo-vpc-frontend-http"
  network     = "${google_compute_network.demo-vpc.name}"
  target_tags = ["frontend"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_instance_template" "demo-vpc-frontend" {
  name_prefix  = "demo-vpc-frontend-"
  machine_type = "f1-micro"
  region       = "${var.region}"
  tags         = ["frontend"]

  disk {
    source_image = "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.demo-vpc-frontend.self_link}"
  }

  metadata {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = <<EOF
apt-get install -y nginx
echo -e "server {" > /etc/nginx/sites-available/default
echo -e "listen 80 default_server;" >> /etc/nginx/sites-available/default
echo -e "listen [::]:80 default_server;" >> /etc/nginx/sites-available/default
echo -e "root /var/www/html;" >> /etc/nginx/sites-available/default
echo -e "index index.html index.htm index.nginx-debian.html;" >> /etc/nginx/sites-available/default
echo -e "server_name _;" >> /etc/nginx/sites-available/default
echo -e "location / {" >> /etc/nginx/sites-available/default
echo -e "proxy_pass http://${var.lb_ip_api}:8080;" >> /etc/nginx/sites-available/default
echo -e "try_files $uri $uri/ =404;" >> /etc/nginx/sites-available/default
echo -e "}" >> /etc/nginx/sites-available/default
echo -e "}" >> /etc/nginx/sites-available/default
systemctl restart nginx
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "demo-vpc-frontend" {
  name               = "demo-vpc-frontend"
  zone               = "${var.region}-a"
  base_instance_name = "demo-vpc-frontend"
  instance_template  = "${google_compute_instance_template.demo-vpc-frontend.self_link}"
  target_pools       = ["${google_compute_target_pool.demo-vpc-frontend.self_link}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_forwarding_rule" "demo-vpc-frontend" {
  name       = "demo-vpc-frontend"
  target     = "${google_compute_target_pool.demo-vpc-frontend.self_link}"
  port_range = "80"
  ip_address = "${google_compute_address.demo-vpc-frontend.address}"
}

resource "google_compute_target_pool" "demo-vpc-frontend" {
  name = "demo-vpc-frontend"

  health_checks = [
    "${google_compute_http_health_check.demo-vpc-frontend.name}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_autoscaler" "demo-vpc-frontend" {
  name   = "demo-vpc-frontend"
  zone   = "${var.region}-a"
  target = "${google_compute_instance_group_manager.demo-vpc-frontend.self_link}"

  autoscaling_policy = {
    max_replicas = 2
    min_replicas = 2

    cpu_utilization {
      target = 0.6
    }
  }
}

resource "google_compute_http_health_check" "demo-vpc-frontend" {
  name                = "demo-vpc-frontend"
  request_path        = "/"
  timeout_sec         = 5
  check_interval_sec  = 5
  unhealthy_threshold = 2
  port                = 80
}

output frontend_address {
  value       = "http://${google_compute_address.demo-vpc-frontend.address}"
  description = "URL to open. You should see debian-apache2 default page."
}

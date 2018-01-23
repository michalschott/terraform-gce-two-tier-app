resource "google_compute_subnetwork" "demo-vpc-frontend" {
  name          = "demo-vpc-europe-west2-frontend"
  ip_cidr_range = "192.168.2.0/24"
  network       = "${google_compute_network.demo-vpc.self_link}"
  region        = "${var.region}"
}

# Commented out due to limits
# resource "google_compute_address" "demo-vpc-frontend" {
#   name   = "demo-vpc-frontend"
#   region = "${var.region}"
# }

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

resource "google_compute_instance" "demo-vpc-frontend" {
  name         = "demo-vpc-frontend"
  machine_type = "f1-micro"
  zone         = "${var.region}-a"
  tags         = ["frontend"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.demo-vpc-frontend.self_link}"

    access_config {
      nat_ip = ""

      #nat_ip = "${google_compute_address.demo-vpc-frontend.address}"
    }
  }

  metadata {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = <<EOF
apt-get install -y nginx && \
echo "server {
  listen 80 default_server;
  listen [::]:80 default_server;
  root /var/www/html;
  index index.html index.htm index.nginx-debian.html;
  server_name _;
  location / {
    proxy_pass http://demo-vpc-api:8080;
    try_files $uri $uri/ =404;
  }
}" > /etc/nginx/sites-available/default && \
systemctl restart nginx
EOF

  depends_on = ["google_compute_instance.demo-vpc-bastion", "google_compute_firewall.demo-vpc-bastion-nat"]
}

output frontend_address {
  value       = "http://${google_compute_instance.demo-vpc-frontend.network_interface.0.access_config.0.assigned_nat_ip}"
  description = "URL to open. You should see debian-apache2 default page."
}

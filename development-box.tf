provider "google" {
  credentials = "${ file("account.json") }"
  project     = "${var.project_id}"
  region      = "us-west1"
}

resource "google_compute_firewall" "allow-ssh" {
  name        = "allow-ssh"
  description = "allow inbound ssh connectivity"
  network     = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["allow-ssh"]
}

resource "google_compute_instance" "development-box" {
  name        = "development-box"
  description = "Micro for docker development"

  machine_type = "f1-micro"
  zone         = "us-west1-a"

  disk = {
    image = "coreos-stable-1298-6-0-v20170315"
  }

  network_interface = {
    network       = "default"
    access_config = {}
  }

  tags = [
    "allow-ssh"
  ]

  connection {
    type        = "ssh"
    user        = "${var.remote_user}"
    private_key = "${file("keys/id_rsa")}"
  }

}
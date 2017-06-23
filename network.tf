resource "google_compute_network" "development" {
  name = "development"
}

# development subnet for docker and nodejs
resource "google_compute_subnetwork" "node-docker" {
  name          = "node-docker"
  network       = "${google_compute_network.development.name}"
  ip_cidr_range = "10.138.0.0/20"
}

# will be added for entire network
resource "google_compute_firewall" "allow-ssh" {
  name        = "allow-ssh"
  description = "allow inbound ssh connectivity"
  network     = "${google_compute_network.development.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# will be added for subnet
resource "google_compute_firewall" "allow-node" {
  name        = "allow-node"
  description = "allow inbound connectivity for node apps"
  network     = "${google_compute_network.development.name}"

  allow {
    protocol = "tcp"
    ports    = ["80", "3000", "8080", "8081", "8082", "8083", "8084", "8085"]
  }

  target_tags = ["allow-node"]
}

# open swarm ports for clustering
resource "google_compute_firewall" "swarm" {
  name        = "swarm"
  description = "Docker swarm firewall rules"
  network     = "${google_compute_network.development.name}"

  allow {
    protocol = "tcp"
    ports    = ["2377", "7946"]
  }

  allow {
    protocol = "udp"
    ports    = ["4789", "7946"]
  }

  source_tags = ["manager", "worker"]
  target_tags = ["manager", "worker"]
}
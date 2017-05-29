provider "google" {
  credentials = "${ file("account.json") }"
  project     = "${var.project_id}"
  region      = "us-west1"
}

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
  description = "allow inbound connectivity for done apps"
  network     = "${google_compute_network.development.name}"

  allow {
    protocol = "tcp"
    ports    = ["3000", "8080", "8081", "8082", "8083", "8084", "8085"]
  }

  target_tags = ["allow-node"]
}

resource "google_compute_instance" "development-box" {
  name        = "development-box"
  description = "Micro instance for development"

  machine_type = "g1-small"
  zone         = "us-west1-a"

  disk = {
    image = "coreos-alpha-1423-0-0-v20170525"
  }

  network_interface = {
    subnetwork = "${google_compute_subnetwork.node-docker.name}"
    access_config {}
  }

  tags = [
    "allow-node"
  ]

  connection {
    type        = "ssh"
    user        = "${var.remote_user}"
    private_key = "${file("keys/id_rsa")}"
  }

  provisioner "file" {
    source      = "keys/github_rsa"
    destination = "~/.ssh/id_rsa"
  }

  provisioner "file" {
    source      = "files/.bashrc"
    destination = "~/.devrc"
  }

  # todo: use ansible to do some of this
  provisioner "remote-exec" {
    inline = [
      # modify private key perms
      "chmod 600 .ssh/id_rsa",

      # replace bashrc with custom
      "mv -f ~/.devrc ~/.bashrc",
      
      # install nvm and nodejs
      "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash && NVM_DIR=\"$HOME/.nvm\" && \\. \"$NVM_DIR/nvm.sh\"",
      "nvm install v7.2.0",

      # don't verify github fingerprint
      "echo -e \"Host github.com\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config",
      
      # create project dir and clone repositories
      "mkdir projects && cd projects",
      "for repo in ${join(" ", var.git_repositories)}; do git clone $repo; done"
    ]
  }
}

output "development-box-ip" {
  value = "${google_compute_instance.development-box.network_interface.0.access_config.0.assigned_nat_ip}"
}
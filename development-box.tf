provider "google" {
  credentials = "${ file("account.json") }"
  project     = "${var.project_id}"
  region      = "us-west1"
}

# this isn't necessary, but doesn't hurt to be explicit
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

resource "google_compute_firewall" "allow-node" {
  name        = "allow-node"
  description = "allow inbound connectivity for done apps"
  network     = "default"

  allow {
    protocol = "tcp"
    ports    = ["3000", "8080", "8081", "8082", "8083", "8084", "8085"]
  }

  target_tags = ["allow-node"]
}

resource "google_compute_instance" "development-box" {
  name        = "development-box"
  description = "Micro instance for development"

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
    "allow-ssh",
    "allow-node"
  ]

  connection {
    type        = "ssh"
    user        = "${var.remote_user}"
    private_key = "${file("keys/id_rsa")}"
  }

  provisioner "file" {
    source = "keys/github_rsa"
    destination = "~/.ssh/id_rsa"
  }

  provisioner "file" {
    source = "files/.bashrc"
    destination = "~/.devrc"
  }

  # todo: use ansible to do some of this
  provisioner "remote-exec" {
    inline = [
      # modify private key perms
      "chmod 600 .ssh/id_rsa",

      # replace bashrc with custom
      "mv -f ~/.devrc ~/.bashrc",

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
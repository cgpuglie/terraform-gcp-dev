resource "google_compute_instance" "swarm-manager" {
  name        = "swarm-manager-${count.index}"
  description = "Docker Swarm Manager"
  count       = "${var.swarm-manager-count}" # reduce to 0 to incur no costs

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
    "allow-node",
    "manager"
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
      
      # initialize a swarm
      "docker swarm init",

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

resource "google_compute_instance" "swarm-worker" {
  name        = "swarm-worker-${count.index}"
  description = "Docker Swarm Worker Node"

  count        = "${var.swarm-worker-count}"
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
    "allow-node",
    "manager"
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
      
      # join managers swarm, requires ssh between manager and worker to get token
      "sudo docker swarm join --token $(ssh -o StrictHostKeyChecking=no ${var.remote_user}@${google_compute_instance.swarm-manager.0.network_interface.0.access_config.0.assigned_nat_ip} 'sudo docker swarm join-token -q worker') ${google_compute_instance.swarm-manager.0.network_interface.0.address}:2377;"
    ]
  }

}

output "swarm-manager-ips" {
  value = ["${google_compute_instance.swarm-manager.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}

output "swarm-worker-ips" {
  value = ["${google_compute_instance.swarm-worker.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}


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
      "mv -f ~/.devrc ~/.bashrc"
    ]
  }
}

resource "null_resource" "run_ansible" {
  triggers {
    cluster_instance_ids = "${join(",", google_compute_instance.swarm-manager.*.id)}, ${join(",", google_compute_instance.swarm-worker.*.id)}"
  }

  provisioner "local-exec" {
    # command = "echo '[swarm-manager] \n ${join("\n", ${google_compute_instance.swarm-manager.*.network_interface.0.access_config.0.assigned_nat_ip})} \n\n [swarm-worker] \n ${join("\n", ${google_compute_instance.swarm-worker.*.network_interface.0.access_config.0.assigned_nat_ip})}' > inventory.ans"
    command = <<EOF
    cat <<INV > swarm-hosts
[swarm-manager]
${join("\n", google_compute_instance.swarm-manager.*.network_interface.0.access_config.0.assigned_nat_ip)}

[swarm-worker]
${join("\n", google_compute_instance.swarm-worker.*.network_interface.0.access_config.0.assigned_nat_ip)}
INV
EOF
  }
}

output "swarm-manager-ips" {
  value = ["${google_compute_instance.swarm-manager.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}

output "swarm-worker-ips" {
  value = ["${google_compute_instance.swarm-worker.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}


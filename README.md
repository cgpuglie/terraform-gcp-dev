## GCP Development Environment
CoreOS based development env for GCP

### Prereqs
You've installed Terraform or can run it through Docker

You've created a GCP Project

You've added a Service Account

You've configured an SSH key for your servers

### Usage
Create keys directory containing id_rsa (ssh private key)

Download account.json file for GCP project for authentication

Create config.tf file
```ruby
# project to use
variable "project_id" {
  default = "PROJECT_ID"
}

# username for ssh access
variable "remote_user" {
  default = "USERNAME"
}

# list of repositories to clone to ~/projects/
variable "git_repositories" {
  type    = "list"
  default = [
    "git@github.com:cgpuglie/GCP-Terraform-DockerSwarm.git"
  ]
}
```

Run Terraform
```bash
terraform apply
```
OR
```bash
docker run -it \
  -v$PWD:/data \
  -w/data \
  hashicorp/terraform:light apply
```

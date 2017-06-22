## GCP Development Environment
CoreOS based development env for GCP

### Prereqs
You've installed Terraform or can run it through Docker

You've created a GCP Project

You've added a Service Account

You've configured an SSH key for your servers

### Usage
Create keys directory containing id_rsa (ssh private key for github and gce servers)

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

# dev vm counts - reducing to 0 will destroy machines, but leave other objects intact
variable "development-count" {
  default = 1
}

# worker vm counts - for swarm mode
variable "development-worker-count" {
  default = 0
}
```
#### Initialize backend
```bash
terraform init -backend-config="credentials=$(cat account.json | jq -c)"
```

#### Run Terraform
```bash
terraform apply
```
#### Using Docker
If you have docker installed, you can run terraform commands with the official docker image.
```bash
docker run -it \
  -v$PWD:/data \
  -w/data \
  hashicorp/terraform:light [COMMAND]
```
#### Exporting the master IP
Export the dev IP as a variable for later use if desired
TODO: add replica ips to output
```
export devIp=`terraform output development-box-ip`
```

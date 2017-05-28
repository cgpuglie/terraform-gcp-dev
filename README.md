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
variable "project_id" {
  default = "PROJECT_ID"
}

variable "remote_user" {
  default = "USERNAME"
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
  hashicorp/terraform:light plan
```

provider "google" {
  credentials = "${ file("secret.json") }"
  project     = "${var.project_id}"
  region      = "us-west1"
}
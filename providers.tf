provider "google" {
  credentials = "${file("./crd/terraform.json")}"
  project     = var.project_id
  region      = var.region
}



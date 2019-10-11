provider "google" {
  credentials = "${file("./crd/testbuild-252808-e13576bdffb8.json")}"
  project     = var.project_id
  region      = var.region
}



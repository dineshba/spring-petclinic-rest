terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.75.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = "us-central1-c"
}
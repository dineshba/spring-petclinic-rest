data "google_compute_network" "default" {
  name = "default"
}

data "google_compute_subnetwork" "default" {
  name   = "default"
  region = var.region
}

resource "google_compute_address" "backend_internal_address" {
  name         = "backend-internal-address"
  subnetwork   = data.google_compute_subnetwork.default.id
  address_type = "INTERNAL"
  region       = var.region
}

resource "google_compute_address" "postgres_internal_address" {
  name         = "postgres-internal-address"
  subnetwork   = data.google_compute_subnetwork.default.id
  address_type = "INTERNAL"
  region       = var.region
}

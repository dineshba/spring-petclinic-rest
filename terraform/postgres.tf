data "google_compute_image" "postgres_image" {
  name    = var.postgres_image_id
  project = var.project
}

resource "google_compute_instance" "postgres" {
  name         = "postgres"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.postgres_image.self_link
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.postgres_internal_address.address
    }
  }
}
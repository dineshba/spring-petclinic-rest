data "google_compute_image" "image" {
  name    = var.image_name
  project = var.project
}

resource "google_compute_instance_template" "instance_template" {
  name_prefix  = "${var.name}-instance-template"
  machine_type = var.machine_type
  region       = var.region

  disk {
    source_image = data.google_compute_image.image.self_link
    auto_delete  = true
    boot         = true
  }

  tags = var.tags

  network_interface {
    network = var.network
  }

  lifecycle {
    create_before_destroy = true
  }

  metadata_startup_script = var.metadata_startup_script
}

resource "google_compute_instance_group_manager" "igm" {
  name = "${var.name}-igm"

  base_instance_name = var.name
  zone               = var.zone

  version {
    instance_template = google_compute_instance_template.instance_template.id
  }

  target_size = var.target_size

  dynamic "named_port" {
    for_each = {
      for named_port in var.named_ports : named_port.name => named_port.port
    }
    content {
      name = named_port.key
      port = named_port.value
    }
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = var.health_check_initial_delay_sec
  }
}

resource "google_compute_health_check" "autohealing" {
  name                = "${var.name}-autohealing-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    request_path = var.health_check_request_path
    port         = var.health_check_port
  }
}

resource "google_compute_firewall" "default" {
  name    = "${var.name}-allow-health-check"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = [var.health_check_port]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
}
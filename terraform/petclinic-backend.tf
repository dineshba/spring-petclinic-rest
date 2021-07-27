locals {
  be-tag = "petclinic-be"
}

data "google_compute_image" "application_image" {
  name    = var.backend_image_id
  project = var.project
}

resource "google_compute_instance_template" "petclinic_application_instance_template" {
  name_prefix  = "instance-template-"
  machine_type = "e2-medium"
  region       = "us-central1"

  disk {
    source_image = data.google_compute_image.application_image.self_link
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
  }

  metadata_startup_script = <<EOF
export SPRING_DATASOURCE_URL=jdbc:postgresql://${google_compute_instance.postgres.network_interface.0.network_ip}:5432/petclinic
export SPRING_PROFILES_ACTIVE=postgresql,spring-data-jpa
export SPRING_JPA_HIBERNATE_DDLAUTO=update
java -jar /app/spring-petclinic-rest-2.4.2.jar
EOF

}

resource "google_compute_instance_group_manager" "petclinic_application_igm" {
  name = "petclinic-application-${substr(google_compute_instance_template.petclinic_application_instance_template.id, -26, -1)}"

  base_instance_name = "petclinic-application"
  zone               = "us-central1-a"

  version {
    instance_template = google_compute_instance_template.petclinic_application_instance_template.id
  }

  target_size = 2

  named_port {
    name = "http"
    port = "9966"
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 120
  }
}

resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/petclinic/actuator/health"
    port         = "9966"
  }
}

resource "google_compute_firewall" "default" {
  name    = "allow-health-check"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["9966"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
}

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

output "load_balancer_ip_address" {
  value = module.gce-ilb.ip_address
}

module "gce-ilb" {
  source  = "GoogleCloudPlatform/lb-internal/google"
  version = "~> 2.0"
  region  = var.region
  name    = "backend-ilb-${substr(google_compute_instance_group_manager.petclinic_application_igm.id, -26, -1)}"
  ports   = ["9966"]
  health_check = {
    type                = "http"
    check_interval_sec  = 10
    healthy_threshold   = 4
    timeout_sec         = 3
    unhealthy_threshold = 5
    response            = ""
    proxy_header        = "NONE"
    port                = 9966
    port_name           = "http"
    request             = ""
    request_path        = "/petclinic/actuator/health"
    host                = ""
    enable_log          = false
  }

  ip_address  = google_compute_address.backend_internal_address.address
  target_tags = [local.be-tag]
  source_tags = [local.fe-tag]
  backends = [
    { group = google_compute_instance_group_manager.petclinic_application_igm.instance_group, description = "" },
  ]
}
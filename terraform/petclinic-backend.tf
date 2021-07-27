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
  name = "petclinic-application"

  base_instance_name = "petclinic-application"
  zone               = "us-central1-a"

  version {
    instance_template = google_compute_instance_template.petclinic_application_instance_template.id
  }

  target_size = 2

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


module "lb" {
  source = "github.com/gruntwork-io/terraform-google-load-balancer.git//modules/internal-load-balancer?ref=v0.2.0"

  name    = "petclinic-lb"
  region  = var.region
  project = var.project

  backends = [
    {
      description = "Instance group for internal-load-balancer test"
      group       = google_compute_instance_group_manager.petclinic_application_igm.instance_group
    },
  ]

  # This setting will enable internal DNS for the load balancer
  service_label = "petclinic-lb"

  # network    = default
  # subnetwork = module.vpc_network.public_subnetwork

  health_check_port = 9966
  http_health_check = false
  target_tags       = [local.be-tag]
  source_tags       = [local.fe-tag]
  ports             = ["9966"]
}

output "load_balancer_domain_name" {
  value = module.lb.load_balancer_domain_name

}

output "load_balancer_ip_address" {
  value = module.lb.load_balancer_ip_address
}
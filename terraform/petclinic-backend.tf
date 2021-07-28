locals {
  be-tag = "petclinic-be"
}

module "backend_instance_group" {
  source      = "./modules/instance-group"
  image_name  = var.backend_image_id
  project     = var.project
  region      = var.region
  zone        = var.zone
  network     = data.google_compute_network.default.name
  tags        = [local.be-tag]
  name        = "be-petclinic"
  target_size = 2
  named_ports = [
    {
      name = "http"
      port = "9966"
  }]
  health_check_initial_delay_sec = 120
  health_check_request_path      = "/petclinic/actuator/health"
  health_check_port              = "9966"
  metadata_startup_script        = <<EOF
export SPRING_DATASOURCE_URL=jdbc:postgresql://${google_compute_address.postgres_internal_address.address}:5432/petclinic
export SPRING_PROFILES_ACTIVE=postgresql,spring-data-jpa
export SPRING_JPA_HIBERNATE_DDLAUTO=update
java -jar /app/spring-petclinic-rest-2.4.2.jar
EOF
}

module "gce-ilb" {
  source  = "GoogleCloudPlatform/lb-internal/google"
  version = "~> 2.0"
  region  = var.region
  name    = "backend-ilb"
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
    { group = module.backend_instance_group.self_link, description = "" },
  ]
}
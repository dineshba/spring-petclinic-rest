locals {
  fe-tag = "petclinic-fe"
}

data "google_compute_image" "fe_application_image" {
  name    = var.frontend_image_id
  project = var.project
}

resource "google_compute_instance_template" "petclinic_fe_instance_template" {
  name_prefix  = "fe-instance-template-"
  machine_type = "e2-medium"
  region       = "us-central1"

  disk {
    source_image = data.google_compute_image.fe_application_image.self_link
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
  }

  tags = ["http-server", local.fe-tag]

  metadata_startup_script = <<EOF
BACKEND_ADDR=${module.lb.load_balancer_ip_address} envsubst \$BACKEND_ADDR < /etc/nginx/nginx.conf.tpl > /etc/nginx/nginx.conf
/etc/init.d/nginx reload
EOF

}

resource "google_compute_instance_group_manager" "petclinic_fe_igm" {
  name = "fe-petclinic-application-${substr(google_compute_instance_template.petclinic_fe_instance_template.id, -26, -1)}"

  base_instance_name = "fe-petclinic-application"
  zone               = "us-central1-a"

  version {
    instance_template = google_compute_instance_template.petclinic_fe_instance_template.id
  }

  named_port {
    name = "http"
    port = "80"
  }

  target_size = 1

  auto_healing_policies {
    health_check      = google_compute_health_check.fe_health_check.id
    initial_delay_sec = 30
  }
}

resource "google_compute_health_check" "fe_health_check" {
  name                = "fe-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/"
    port         = "80"
  }
}

resource "google_compute_firewall" "fe_health_check" {
  name    = "allow-fe-health-check"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = [local.fe-tag]

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
}

# data "google_compute_network" "default" {
#   name = "default"
# }


# module "fe_lb" {
#   source = "github.com/gruntwork-io/terraform-google-load-balancer.git//modules/http-load-balancer"

#   name    = "fe-petclinic-lb"
#   # region  = var.region
#   project = var.project

#   url_map = google_compute_instance_group_manager.petclinic_fe_igm.instance_group
# }

# output "fe-load_balancer_ip_address" {
#   value = module.fe_lb.load_balancer_ip_address
# }

module "gce-lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "~> 4.4"

  project     = var.project
  name        = "group-http-lb-${substr(google_compute_instance_group_manager.petclinic_fe_igm.id, -26, -1)}"
  target_tags = [local.fe-tag]
  backends = {
    default = {
      description             = null
      protocol                = "HTTP"
      port                    = "80"
      port_name               = "http"
      timeout_sec             = 10
      enable_cdn              = false
      custom_request_headers  = null
      custom_response_headers = null
      security_policy         = null

      connection_draining_timeout_sec = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null

      health_check = {
        check_interval_sec  = null
        timeout_sec         = null
        healthy_threshold   = null
        unhealthy_threshold = null
        request_path        = "/"
        port                = 80
        host                = null
        logging             = null
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          # Each node pool instance group should be added to the backend.
          group                        = google_compute_instance_group_manager.petclinic_fe_igm.instance_group
          balancing_mode               = null
          capacity_scaler              = null
          description                  = null
          max_connections              = null
          max_connections_per_instance = null
          max_connections_per_endpoint = null
          max_rate                     = null
          max_rate_per_instance        = null
          max_rate_per_endpoint        = null
          max_utilization              = null
        },
      ]

      iap_config = {
        enable               = false
        oauth2_client_id     = null
        oauth2_client_secret = null
      }
    }
  }
}

output "external_ip" {
  value = module.gce-lb-http.external_ip
}
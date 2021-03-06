locals {
  fe-tag = "petclinic-fe"
}

module "angular_instance_group" {
  source     = "./modules/instance-group"
  image_name = var.frontend_image_id
  project    = var.project
  region     = var.region
  zone       = var.zone
  network    = data.google_compute_network.default.name
  tags       = [local.fe-tag]
  name       = "fe-petclinic"
  named_ports = [
    {
      name = "http"
      port = "80"
  }]
  health_check_initial_delay_sec = 60
  metadata_startup_script        = <<EOF
BACKEND_ADDR=${google_compute_address.backend_internal_address.address} envsubst \$BACKEND_ADDR < /etc/nginx/nginx.conf.tpl > /etc/nginx/nginx.conf
/etc/init.d/nginx reload
EOF

}

module "gce-lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "~> 4.4"

  project     = var.project
  name        = "group-http-lb"
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
          group                        = module.angular_instance_group.self_link
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

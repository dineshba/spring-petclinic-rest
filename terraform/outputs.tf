output "backend_internal_address" {
  value = module.gce-ilb.ip_address
}

output "postgres_internal_address" {
  value = google_compute_address.postgres_internal_address.address
}

output "frontend_external_address" {
  value = module.gce-lb-http.external_ip
}
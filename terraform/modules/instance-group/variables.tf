variable "image_name" {
  type = string
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "network" {
  type = string
}

variable "tags" {
  type = list(string)
}

variable "metadata_startup_script" {
  type = string
}

variable "name" {
  type = string
}

variable "target_size" {
  type    = number
  default = 1
}

variable "named_ports" {
  type = list(object({
    name = string
    port = string
  }))
}

variable "health_check_request_path" {
  type    = string
  default = "/"
}

variable "health_check_port" {
  type    = string
  default = "80"
}

variable "health_check_initial_delay_sec" {
  type = number
}
packer {
  required_plugins {
    googlecompute = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable project_id {
  type = string
}

variable zone {
  type    = string
  default = "us-central1-a"
}

source "googlecompute" "build" {
  project_id   = var.project_id
  source_image = "ubuntu-1804-bionic-v20210623"
  ssh_username = "root"
  zone         = var.zone
}

build {
  sources = [
    "source.googlecompute.build"
  ]

  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt update && apt install default-jre -y",
      "mkdir -p /app"
    ]
  }

  provisioner "file" {
    source      = "target/spring-petclinic-rest-2.4.2.jar"
    destination = "/app/spring-petclinic-rest-2.4.2.jar"
  }

  post-processor "manifest" {}
}
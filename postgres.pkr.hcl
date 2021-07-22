packer {
  required_plugins {
    googlecompute = {
      version = "~> 1.0.0"
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
  image_name   = "petclinic-postgres-v1"
  ssh_username = "root"
  zone         = var.zone
}

build {
  sources = [
    "source.googlecompute.build"
  ]

  provisioner "shell" {
    inline = [
      "apt update && apt -y install postgresql postgresql-client postgresql-contrib",
      "sudo -u postgres createdb petclinic"
    ]
  }

  post-processor "manifest" {}
}

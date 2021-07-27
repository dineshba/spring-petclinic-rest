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

variable postgres_user_password {
  type      = string
  sensitive = true
}

source "googlecompute" "build" {
  project_id   = var.project_id
  source_image = "ubuntu-1804-bionic-v20210623"
  image_name   = "petclinic-postgres-{{timestamp}}"
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
      "sudo -u postgres createdb petclinic",
      "sudo -u postgres psql -c \"ALTER ROLE postgres WITH password '${var.postgres_user_password}'\"",
      "echo \"listen_addresses = '*'\" >> /etc/postgresql/10/main/postgresql.conf",
      "echo \"host    all       all   0.0.0.0/0     md5\" >> /etc/postgresql/10/main/pg_hba.conf"
    ]
  }

  post-processor "manifest" {}
}
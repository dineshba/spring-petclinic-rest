terraform {

  backend "gcs" {
    bucket = "terraform-state-petclinic"
    prefix = "deployment"
  }
}
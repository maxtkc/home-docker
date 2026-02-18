terraform {
  required_providers {
    forgejo = {
      source  = "svalabs/forgejo"
      version = "~> 1.2"
    }
  }

  required_version = ">= 1.11"

  backend "local" {
    path = "terraform.tfstate"
  }
}

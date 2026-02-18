terraform {
  required_providers {
    porkbun = {
      source  = "marcfrederick/porkbun"
      version = "1.3.1"
    }
  }

  required_version = ">= 1.11"

  backend "local" {
    path = "terraform.tfstate"
  }
}

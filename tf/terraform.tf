terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.9.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
  }

  required_version = ">= 1.11"
}

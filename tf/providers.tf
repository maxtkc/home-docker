# Default provider — always defined first
provider "docker" {
  host = var.docker_host
}

provider "random" {}

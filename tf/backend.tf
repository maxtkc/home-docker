# Local state is acceptable for a home server.
# Ensure terraform.tfstate is gitignored.
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

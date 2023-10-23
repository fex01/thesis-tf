terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

resource "random_pet" "prefix" {
  length = 2
}

output "prefix" {
  value = random_pet.prefix.id
}
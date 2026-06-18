terraform {
  required_version = ">= 1.5.0"

  # Your "dependencies" block. random + null are tiny demo providers.
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Generates a friendly name like "harmless-grouper". Think of it as a resource
# whose only job is to produce a value.
resource "random_pet" "name" {
  length    = 2
  separator = "-"
}

# A do-nothing resource that runs a local command when created. We use it to
# *see* something happen on apply.
resource "null_resource" "greeting" {
  # If this map ever changes, the resource is destroyed + recreated.
  triggers = {
    pet = random_pet.name.id
  }

  provisioner "local-exec" {
    command = "echo Hello from ${random_pet.name.id}"
  }
}

# Like a component returning a value up to its parent. Printed after apply.
output "pet_name" {
  value = random_pet.name.id
}
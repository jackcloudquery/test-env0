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
  length    = 4
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

# Forces a real (non-skipped) apply on EVERY deployment: the timestamp() trigger
# changes each run, so the resource is recreated and env0 never marks the run as a
# skipped apply. This keeps each deploy fast (<1s) and successful while still
# counting toward the monthly-runs cap (skipped applies don't count).
resource "null_resource" "always_apply" {
  triggers = {
    run_at = timestamp()
  }

  provisioner "local-exec" {
    command = "echo 'Applied at ${timestamp()}'"
  }
}

# --- Optional free-tier timeout test ---------------------------------------
# Disabled by default (hang_seconds = 0) so normal deploys finish in seconds and
# succeed. To reproduce the Free plan's 20-minute Task Execution Timeout, set an
# env0 environment variable TF_VAR_hang_seconds greater than the deployment cap
# (e.g. 1300 against the 1200s free-tier cap, or 60 against a temporarily-shrunk
# cap). It prints a line every 30s to keep the agent heartbeating, so it produces
# an *execution* timeout, not a heartbeat timeout.
variable "hang_seconds" {
  description = "Seconds the apply should sleep. 0 (default) = fast, succeeding deploy. Set > the deployment cap to trigger a Task Execution Timeout."
  type        = number
  default     = 0
}

resource "null_resource" "hang" {
  count = var.hang_seconds > 0 ? 1 : 0

  # timestamp() changes every plan, so the sleep re-runs on every deployment.
  triggers = {
    run_at = timestamp()
  }

  provisioner "local-exec" {
    command = "echo 'Hanging to exceed the free-tier timeout...'; i=0; while [ \"$i\" -lt ${var.hang_seconds} ]; do echo \"...still running $i/${var.hang_seconds}s\"; sleep 30; i=$((i+30)); done"
  }
}

# Like a component returning a value up to its parent. Printed after apply.
output "pet_name" {
  value = random_pet.name.id
}

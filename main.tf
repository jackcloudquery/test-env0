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

# --- Free-tier timeout test -------------------------------------------------
# Forces the deployment to run longer than the Free plan's 20-minute cap so the
# run is killed with a "Task Execution Timeout" (the cap), which is what the
# free-tier upgrade hint keys on.
#
# Set this lower via an env0 environment variable (name: TF_VAR_hang_seconds)
# if you temporarily shrank FREE_TIER_DEPLOYMENT_AGENT_TIMEOUT on the backend
# for a faster test — e.g. TF_VAR_hang_seconds=60 against a 30s cap.
variable "hang_seconds" {
  description = "Seconds the apply should sleep. Must exceed the deployment timeout to trigger a TIMEOUT."
  type        = number
  default     = 1300 # ~21.7 min, just over the 20-minute (1200s) free-tier cap
}

# A do-nothing resource that just burns wall-clock time on apply. It prints a
# line every 30s so the agent keeps heartbeating (< the 60s heartbeat window) —
# that guarantees an *execution* timeout (Task Execution Timeout), not a
# heartbeat timeout, which is the case the free-tier hint is meant to catch.
resource "null_resource" "hang" {
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
variable "name" {
  type        = string
  description = "Container App name."
}

variable "resource_group_name" {
  type = string
}

variable "container_app_environment_id" {
  type = string
}

variable "user_assigned_identity_id" {
  type        = string
  description = "User-assigned MI bound to the app. Used for ACR pull and any KV/Storage/Cosmos/Event Hub data-plane access."
}

variable "registry_login_server" {
  type        = string
  description = "ACR login server, e.g. crcomtrainabc123.azurecr.io"
}

variable "image" {
  type        = string
  description = "Full image reference, e.g. crcomtrainabc123.azurecr.io/auth-service:0.1.0"
}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "Plain environment variables. For secret refs use a separate variable in production."
}

variable "secret_env_vars" {
  type        = map(string)
  default     = {}
  sensitive   = true
  description = "Environment variables backed by Container App secrets. Values are still stored in Terraform state."
}

variable "args" {
  type        = list(string)
  default     = []
  description = "Arguments passed to the main container entrypoint."
}

variable "cpu" {
  type    = number
  default = 0.25
}

variable "memory" {
  type    = string
  default = "0.5Gi"
}

variable "min_replicas" {
  type        = number
  default     = 0
  description = "0 enables scale-to-zero (cheapest). Set to 1 for warm latency."
}

variable "max_replicas" {
  type    = number
  default = 2
}

variable "ingress_enabled" {
  type    = bool
  default = true
}

variable "ingress_external" {
  type        = bool
  default     = true
  description = "True for public ingress, false for env-internal only."
}

variable "target_port" {
  type    = number
  default = 8080
}

variable "extra_containers" {
  type = list(object({
    name   = string
    image  = string
    cpu    = number
    memory = string
    env    = optional(map(string), {})
    args   = optional(list(string), [])
    volume_mounts = optional(list(object({
      name     = string
      path     = string
      sub_path = optional(string)
    })), [])
  }))
  default     = []
  description = "Sidecar containers running in the same pod as the main app (e.g. Grafana Alloy)."
}

variable "volume_mounts" {
  type = list(object({
    name     = string
    path     = string
    sub_path = optional(string)
  }))
  default     = []
  description = "Volumes to mount into the main container."
}

variable "volumes" {
  type = list(object({
    name          = string
    storage_type  = optional(string, "EmptyDir")
    storage_name  = optional(string)
    mount_options = optional(string)
  }))
  default     = []
  description = "Container App template volumes available to containers."
}

variable "http_scale_rule" {
  type = object({
    name                = string
    concurrent_requests = number
  })
  default     = null
  description = "When set, enables KEDA's built-in HTTP scaler. Combined with min_replicas = 0 this gives scale-to-zero on HTTP idle and scale-up on incoming requests."
}

variable "custom_scale_rules" {
  type = list(object({
    name             = string
    custom_rule_type = string
    metadata         = map(string)
    identity_id      = optional(string)
    authentications = optional(list(object({
      secret_name       = string
      trigger_parameter = string
    })), [])
  }))
  default     = []
  description = <<-EOT
    KEDA custom scale rules (e.g. azure-eventhub, azure-servicebus, redis).
    `identity_id` should be the user-assigned MI resource ID when the trigger
    auths via workload identity. `authentications` only needed for
    secret/connection-string based triggers.
  EOT
}

variable "tags" {
  type    = map(string)
  default = {}
}

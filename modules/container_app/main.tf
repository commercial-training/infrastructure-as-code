resource "azurerm_container_app" "this" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  registry {
    server   = var.registry_login_server
    identity = var.user_assigned_identity_id
  }

  dynamic "secret" {
    for_each = toset(nonsensitive(keys(var.secret_env_vars)))
    content {
      name  = lower(replace(secret.value, "_", "-"))
      value = var.secret_env_vars[secret.value]
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    dynamic "volume" {
      for_each = { for volume in var.volumes : volume.name => volume }
      content {
        name          = volume.value.name
        storage_type  = volume.value.storage_type
        storage_name  = volume.value.storage_name
        mount_options = volume.value.mount_options
      }
    }

    container {
      name   = var.name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory
      args   = var.args

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = toset(nonsensitive(keys(var.secret_env_vars)))
        content {
          name        = env.value
          secret_name = lower(replace(env.value, "_", "-"))
        }
      }

      dynamic "volume_mounts" {
        for_each = { for mount in var.volume_mounts : "${mount.name}:${mount.path}" => mount }
        content {
          name     = volume_mounts.value.name
          path     = volume_mounts.value.path
          sub_path = volume_mounts.value.sub_path
        }
      }
    }

    dynamic "container" {
      for_each = var.extra_containers
      content {
        name   = container.value.name
        image  = container.value.image
        cpu    = container.value.cpu
        memory = container.value.memory
        args   = container.value.args

        dynamic "env" {
          for_each = container.value.env
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "volume_mounts" {
          for_each = { for mount in container.value.volume_mounts : "${mount.name}:${mount.path}" => mount }
          content {
            name     = volume_mounts.value.name
            path     = volume_mounts.value.path
            sub_path = volume_mounts.value.sub_path
          }
        }
      }
    }

    dynamic "http_scale_rule" {
      iterator = http_rule
      for_each = var.http_scale_rule == null ? [] : [var.http_scale_rule]
      content {
        name                = http_rule.value.name
        concurrent_requests = http_rule.value.concurrent_requests
      }
    }

    dynamic "custom_scale_rule" {
      for_each = { for r in var.custom_scale_rules : r.name => r }
      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata
        identity_id      = custom_scale_rule.value.identity_id

        dynamic "authentication" {
          for_each = custom_scale_rule.value.authentications
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }
  }

  dynamic "ingress" {
    for_each = var.ingress_enabled ? [1] : []
    content {
      external_enabled           = var.ingress_external
      target_port                = var.target_port
      transport                  = "auto"
      allow_insecure_connections = false

      traffic_weight {
        latest_revision = true
        percentage      = 100
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Commercial Training — Azure workload composition (env: training)
#
# Pipeline:
#   client ─► report-service (POST /data) ─► Blob Storage + Event Hub
#                                            Event Hub ─► data-ingest-service ─► Cosmos DB
#
# Auth (separate plane):
#   client ─► auth-service (/auth/login, JWKS) ─► uses Key Vault PKCS#8 PEM
#                                                  secret for JWT signing
#
# Runtime services authenticate via user-assigned managed identity. Grafana uses
# an isolated Azure Files storage account because ACA AzureFile mounts require a
# storage account key.
# -----------------------------------------------------------------------------

# Per-env suffix used for globally-unique resource names (storage, ACR, KV,
# Event Hub namespace, Cosmos). Stored in this env's state, regenerated only
# on first apply.

# if have already resource on Azure RG
# import {
#   to = module.rg.azurerm_resource_group.this
#   id = "/subscriptions/6233ef27-8777-4140-b039-94a89a5e9c56/resourceGroups/rg-commercial-trainning"
# }

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "random_password" "grafana_admin" {
  length  = 24
  special = false
}

locals {
  suffix = random_string.suffix.result

  # Naming convention. ACR/storage/KV have tight length + charset rules, so
  # those drop hyphens. The others use the readable hyphenated form.
  names = {
    log_analytics = "log-${var.name_prefix}-${local.suffix}"
    # acr           = "cr${var.name_prefix}${local.suffix}"
    acr = "crcommerciala9be68"
    # key_vault     = "kv-${var.name_prefix}-${local.suffix}"
    key_vault = "kv-commercial-a9be68"
    # storage       = "st${var.name_prefix}${local.suffix}"
    storage = "stcommerciala9be68"
    # event_hub_ns  = "evhns-${var.name_prefix}-${local.suffix}"
    event_hub_ns   = "evhns-commercial-a9be68"
    service_bus_ns = "sb-${var.name_prefix}-${local.suffix}"
    # cosmos        = "cosmos-${var.name_prefix}-${local.suffix}"
    cosmos        = "cosmos-commercial-a9be68"
    aca_env       = "cae-${var.name_prefix}"
    grafana_store = "stgrafana${local.suffix}"
    mi_auth       = "id-auth-service"
    mi_report     = "id-report-service"
    mi_ingest     = "id-data-ingest-service"
    mi_monitoring = "id-monitoring"
    ca_auth       = "ca-auth-service"
    ca_report     = "ca-report-service"
    ca_ingest     = "ca-data-ingest-service"
    ca_prometheus = "ca-prometheus"
    ca_loki       = "ca-loki"
    ca_grafana    = "ca-grafana"
  }
}

# -----------------------------------------------------------------------------
# Foundation: resource group, log analytics
# -----------------------------------------------------------------------------

module "rg" {
  source = "../../modules/resource_group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "log_analytics" {
  source = "../../modules/log_analytics"

  name                = local.names.log_analytics
  resource_group_name = module.rg.name
  location            = module.rg.location
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Platform: ACR, Key Vault, Storage, Event Hub, Cosmos
# -----------------------------------------------------------------------------

module "acr" {
  source = "../../modules/container_registry"

  name                = local.names.acr
  resource_group_name = module.rg.name
  location            = module.rg.location
  sku                 = "Basic" # cheapest SKU
  tags                = var.tags
}

module "key_vault" {
  source = "../../modules/key_vault"

  name                = local.names.key_vault
  resource_group_name = module.rg.name
  location            = module.rg.location
  tags                = var.tags
}

module "storage" {
  source = "../../modules/storage"

  name                = local.names.storage
  resource_group_name = module.rg.name
  location            = module.rg.location
  tags                = var.tags
}

resource "azurerm_storage_account" "grafana" {
  name                              = local.names.grafana_store
  resource_group_name               = module.rg.name
  location                          = module.rg.location
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  account_kind                      = "StorageV2"
  access_tier                       = "Hot"
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = true
  public_network_access_enabled     = true
  infrastructure_encryption_enabled = true
  tags                              = var.tags
}

resource "azurerm_storage_share" "grafana" {
  name               = "grafana-data"
  storage_account_id = azurerm_storage_account.grafana.id
  quota              = var.grafana_file_share_quota_gb
}

module "event_hub" {
  source = "../../modules/event_hub"

  namespace_name      = local.names.event_hub_ns
  resource_group_name = module.rg.name
  location            = module.rg.location
  sku                 = "Basic" # required for custom consumer groups
  tags                = var.tags
}

module "service_bus" {
  source = "../../modules/service_bus"

  namespace_name      = local.names.service_bus_ns
  resource_group_name = module.rg.name
  location            = module.rg.location
  queue_name          = var.service_bus_queue_name
  sku                 = var.service_bus_sku
  tags                = var.tags
}

module "cosmos" {
  source = "../../modules/cosmos_db"

  account_name        = local.names.cosmos
  resource_group_name = module.rg.name
  location            = module.rg.location
  enable_free_tier    = var.enable_cosmos_free_tier
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Identities — one user-assigned MI per service
# -----------------------------------------------------------------------------

module "mi_auth" {
  source = "../../modules/identity"

  name                = local.names.mi_auth
  resource_group_name = module.rg.name
  location            = module.rg.location
  tags                = var.tags
}

module "mi_report" {
  source = "../../modules/identity"

  name                = local.names.mi_report
  resource_group_name = module.rg.name
  location            = module.rg.location
  tags                = var.tags
}

module "mi_ingest" {
  source = "../../modules/identity"

  name                = local.names.mi_ingest
  resource_group_name = module.rg.name
  location            = module.rg.location
  tags                = var.tags
}

# Role assignments live in role_assignments.tf — same root module, same state.

module "mi_monitoring" {
  source = "../../modules/identity"

  name                = local.names.mi_monitoring
  resource_group_name = module.rg.name
  location            = module.rg.location
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Container Apps environment + apps
# -----------------------------------------------------------------------------

module "aca_env" {
  source = "../../modules/container_app_env"

  name                       = local.names.aca_env
  resource_group_name        = module.rg.name
  location                   = module.rg.location
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = var.tags
}

resource "azurerm_container_app_environment_storage" "grafana" {
  name                         = "grafana-data"
  container_app_environment_id = module.aca_env.id
  account_name                 = azurerm_storage_account.grafana.name
  share_name                   = azurerm_storage_share.grafana.name
  access_key                   = azurerm_storage_account.grafana.primary_access_key
  access_mode                  = "ReadWrite"
}

# Grafana Alloy sidecars. The Azure image bakes in an OTLP receiver config.
# App containers export OTLP metrics/logs to localhost; Alloy forwards metrics
# to Prometheus remote-write and logs to Loki.
locals {
  prometheus_url              = "https://${module.ca_prometheus.fqdn}"
  prometheus_remote_write_url = "${local.prometheus_url}/api/v1/write"
  loki_url                    = coalesce(var.loki_url, "https://${module.ca_loki.fqdn}")
  loki_push_url               = "${local.loki_url}/loki/api/v1/push"
  otel_common_env = {
    JAVA_TOOL_OPTIONS                             = "-javaagent:/otel/opentelemetry-javaagent.jar"
    OTEL_EXPORTER_OTLP_ENDPOINT                   = "http://127.0.0.1:4318"
    OTEL_EXPORTER_OTLP_PROTOCOL                   = "http/protobuf"
    OTEL_INSTRUMENTATION_LOGBACK_APPENDER_ENABLED = "true"
    OTEL_INSTRUMENTATION_MICROMETER_ENABLED       = "true"
    OTEL_LOGS_EXPORTER                            = "otlp"
    OTEL_METRIC_EXPORT_INTERVAL                   = "15000"
    OTEL_METRICS_EXPORTER                         = "otlp"
    OTEL_TRACES_EXPORTER                          = "none"
  }
  otel_auth_env   = merge(local.otel_common_env, { OTEL_SERVICE_NAME = "authentication-service" })
  otel_report_env = merge(local.otel_common_env, { OTEL_SERVICE_NAME = "report-service" })
  otel_ingest_env = merge(local.otel_common_env, { OTEL_SERVICE_NAME = "data-ingest-service" })

  alloy_sidecars = var.enable_grafana_alloy_sidecar ? {
    auth = [{
      name   = "grafana-alloy"
      image  = var.alloy_image
      cpu    = 0.25
      memory = "0.5Gi"
      args   = []
      env = {
        PROMETHEUS_REMOTE_WRITE_URL = local.prometheus_remote_write_url
        LOKI_PUSH_URL               = local.loki_push_url
      }
    }]
    report = [{
      name   = "grafana-alloy"
      image  = var.alloy_image
      cpu    = 0.25
      memory = "0.5Gi"
      args   = []
      env = {
        PROMETHEUS_REMOTE_WRITE_URL = local.prometheus_remote_write_url
        LOKI_PUSH_URL               = local.loki_push_url
      }
    }]
    ingest = [{
      name   = "grafana-alloy"
      image  = var.alloy_image
      cpu    = 0.25
      memory = "0.5Gi"
      args   = []
      env = {
        PROMETHEUS_REMOTE_WRITE_URL = local.prometheus_remote_write_url
        LOKI_PUSH_URL               = local.loki_push_url
      }
    }]
    } : {
    auth   = []
    report = []
    ingest = []
  }
}

module "ca_prometheus" {
  source = "../../modules/container_app"

  name                         = local.names.ca_prometheus
  resource_group_name          = module.rg.name
  container_app_environment_id = module.aca_env.id
  user_assigned_identity_id    = module.mi_monitoring.id
  registry_login_server        = module.acr.login_server
  image                        = var.prometheus_image
  target_port                  = 9090
  ingress_enabled              = true
  ingress_external             = false
  min_replicas                 = 1
  max_replicas                 = 1
  args = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--web.enable-remote-write-receiver",
    "--storage.tsdb.retention.time=7d",
  ]

  tags = var.tags

  depends_on = [azurerm_role_assignment.acr_pull_monitoring]
}

module "ca_loki" {
  source = "../../modules/container_app"

  name                         = local.names.ca_loki
  resource_group_name          = module.rg.name
  container_app_environment_id = module.aca_env.id
  user_assigned_identity_id    = module.mi_monitoring.id
  registry_login_server        = module.acr.login_server
  image                        = var.loki_image
  target_port                  = 3100
  ingress_enabled              = true
  ingress_external             = false
  min_replicas                 = 1
  max_replicas                 = 1
  args = [
    "-config.file=/etc/loki/local-config.yaml",
  ]

  tags = var.tags

  depends_on = [azurerm_role_assignment.acr_pull_monitoring]
}

module "ca_grafana" {
  source = "../../modules/container_app"

  name                         = local.names.ca_grafana
  resource_group_name          = module.rg.name
  container_app_environment_id = module.aca_env.id
  user_assigned_identity_id    = module.mi_monitoring.id
  registry_login_server        = module.acr.login_server
  image                        = var.grafana_image
  target_port                  = 3000
  ingress_enabled              = true
  ingress_external             = true
  min_replicas                 = 1
  max_replicas                 = 1

  volumes = [
    {
      name          = "grafana-data"
      storage_type  = "AzureFile"
      storage_name  = azurerm_container_app_environment_storage.grafana.name
      mount_options = "uid=472,gid=472,dir_mode=0775,file_mode=0664"
    },
  ]

  volume_mounts = [
    {
      name = "grafana-data"
      path = "/var/lib/grafana"
    },
  ]

  env_vars = {
    AZURE_AUTH_TYPE                     = "msi"
    AZURE_CLIENT_ID                     = module.mi_monitoring.client_id
    AZURE_SUBSCRIPTION_ID               = data.azurerm_client_config.current.subscription_id
    AZURE_TENANT_ID                     = data.azurerm_client_config.current.tenant_id
    GF_AZURE_MANAGED_IDENTITY_CLIENT_ID = module.mi_monitoring.client_id
    GF_AZURE_MANAGED_IDENTITY_ENABLED   = "true"
    GF_SECURITY_ADMIN_USER              = var.grafana_admin_user
    GF_USERS_DEFAULT_THEME              = "light"
    LOKI_URL                            = local.loki_url
    PROMETHEUS_URL                      = local.prometheus_url
  }

  secret_env_vars = {
    GF_SECURITY_ADMIN_PASSWORD = random_password.grafana_admin.result
  }

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.acr_pull_monitoring,
    azurerm_role_assignment.azure_monitor_reader_monitoring,
    azurerm_container_app_environment_storage.grafana,
    module.ca_loki,
    module.ca_prometheus,
  ]
}

module "ca_auth" {
  source = "../../modules/container_app"

  name                         = local.names.ca_auth
  resource_group_name          = module.rg.name
  container_app_environment_id = module.aca_env.id
  user_assigned_identity_id    = module.mi_auth.id
  registry_login_server        = module.acr.login_server
  image                        = var.auth_service_image
  target_port                  = 8081
  ingress_enabled              = true
  ingress_external             = true

  # auth-service is the JWKS issuer for report-service. Keep at least one warm
  # replica so report-service token validation never has to wait on a cold
  # start of the issuer.
  min_replicas = 0
  max_replicas = 3

  env_vars = merge({
    APP_JWT_ISSUER             = "https://${local.names.ca_auth}.${module.aca_env.default_domain}"
    AZURE_KEYVAULT_ENDPOINT    = module.key_vault.vault_uri
    AZURE_KEYVAULT_SECRET_NAME = module.key_vault.secret_name
    AZURE_CLIENT_ID            = module.mi_auth.client_id
  }, local.otel_auth_env)

  extra_containers = local.alloy_sidecars.auth

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.acr_pull_auth,
    azurerm_role_assignment.kv_secrets_user_auth,
    module.ca_loki,
    module.ca_prometheus,
  ]
}

module "ca_report" {
  source = "../../modules/container_app"

  name                         = local.names.ca_report
  resource_group_name          = module.rg.name
  container_app_environment_id = module.aca_env.id
  user_assigned_identity_id    = module.mi_report.id
  registry_login_server        = module.acr.login_server
  image                        = var.report_service_image
  target_port                  = 8082
  ingress_enabled              = true
  ingress_external             = true

  # Scale up when HTTP requests are received; scale down to zero when idle.
  min_replicas = 0
  max_replicas = 3

  http_scale_rule = {
    name                = "http-requests"
    concurrent_requests = var.report_http_concurrent_requests
  }

  env_vars = merge({
    # Spring relaxed binding for spring.security.oauth2.resourceserver.jwt.jwk-set-uri
    SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI = "https://${local.names.ca_auth}.${module.aca_env.default_domain}/.well-known/jwks.json"
    AZURE_STORAGE_ENDPOINT                                = module.storage.primary_blob_endpoint
    AZURE_STORAGE_CONTAINER                               = module.storage.data_container_name
    # Event Hubs namespace property takes the SHORT name only — Spring Cloud
    # Azure appends `.servicebus.windows.net` internally. Using the FQDN here
    # produces `<ns>.servicebus.windows.net.servicebus.windows.net`.
    AZURE_EVENTHUB_NAMESPACE    = module.event_hub.namespace_name
    AZURE_EVENTHUB_NAME         = module.event_hub.hub_name
    AZURE_SERVICEBUS_NAMESPACE  = module.service_bus.namespace_name
    AZURE_SERVICEBUS_QUEUE_NAME = module.service_bus.queue_name
    AZURE_CLIENT_ID             = module.mi_report.client_id
  }, local.otel_report_env)

  extra_containers = local.alloy_sidecars.report

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.acr_pull_report,
    azurerm_role_assignment.blob_writer_report,
    azurerm_role_assignment.evh_sender_report,
    azurerm_role_assignment.sb_sender_report,
    module.ca_loki,
    module.ca_prometheus,
  ]
}

module "ca_ingest" {
  source = "../../modules/container_app"

  name                         = local.names.ca_ingest
  resource_group_name          = module.rg.name
  container_app_environment_id = module.aca_env.id
  user_assigned_identity_id    = module.mi_ingest.id
  registry_login_server        = module.acr.login_server
  image                        = var.data_ingest_image
  ingress_enabled              = false # consumer only

  min_replicas = 0
  max_replicas = module.event_hub.partition_count # 1 replica per partition is the EH parallelism cap

  custom_scale_rules = [
    {
      name             = "eventhub-lag"
      custom_rule_type = "azure-eventhub"
      identity_id      = module.mi_ingest.id
      metadata = {
        eventHubNamespace = module.event_hub.namespace_name
        eventHubName      = module.event_hub.hub_name
        # consumerGroup             = module.event_hub.consumer_group_name
        consumerGroup             = "$Default"
        unprocessedEventThreshold = tostring(var.ingest_unprocessed_event_threshold)
        # Java Azure SDK's BlobCheckpointStore uses blob metadata for offsets,
        checkpointStrategy = "blobMetadata"
        storageAccountName = module.storage.name
        blobContainer      = module.storage.checkpoint_container_name
      }
    },
  ]

  env_vars = merge({
    AZURE_EVENTHUB_NAMESPACE = module.event_hub.namespace_name
    AZURE_EVENTHUB_NAME      = module.event_hub.hub_name
    # AZURE_EVENTHUB_CONSUMER_GROUP    = module.event_hub.consumer_group_name
    AZURE_EVENTHUB_CONSUMER_GROUP    = "$Default"
    AZURE_EVENTHUB_INITIAL_POSITION  = "earliest"
    AZURE_SERVICEBUS_NAMESPACE       = module.service_bus.namespace_name
    AZURE_SERVICEBUS_QUEUE_NAME      = module.service_bus.queue_name
    AZURE_CHECKPOINT_STORAGE_ACCOUNT = module.storage.name
    AZURE_CHECKPOINT_CONTAINER       = module.storage.checkpoint_container_name
    AZURE_STORAGE_ENDPOINT           = module.storage.primary_blob_endpoint
    AZURE_STORAGE_CONTAINER          = module.storage.data_container_name
    AZURE_COSMOS_ENDPOINT            = module.cosmos.endpoint
    AZURE_COSMOS_DATABASE            = module.cosmos.database_name
    AZURE_CLIENT_ID                  = module.mi_ingest.client_id
  }, local.otel_ingest_env)

  extra_containers = local.alloy_sidecars.ingest

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.acr_pull_ingest,
    azurerm_role_assignment.evh_receiver_ingest,
    azurerm_role_assignment.sb_receiver_ingest,
    azurerm_role_assignment.blob_checkpoint_ingest,
    azurerm_cosmosdb_sql_role_assignment.cosmos_writer_ingest,
    module.ca_loki,
    module.ca_prometheus,
  ]
}

# Commercial Training — Azure Infrastructure (Terraform)

Provisions the Azure footprint for the three-service training pipeline:

```
client ─► report-service (POST /data) ─► Blob Storage
                                       └─► Event Hub ─► data-ingest-service ─► Cosmos DB
client ─► auth-service (/auth/login, JWKS) ─► Key Vault PKCS#8 PEM secret
```

Both `report-service` and `data-ingest-service` can optionally run a Grafana
Alloy sidecar to ship metrics/logs.

## Layout

```
terraform/
├── bootstrap/            # one-off: creates the state backend (local state)
├── envs/
│   └── training/
│       ├── backend.tf            # remote state backend config
│       ├── providers.tf          # provider versions & features
│       ├── variables.tf          # env inputs
│       ├── main.tf               # module composition (rg, platform, apps)
│       ├── role_assignments.tf   # all RBAC wiring, kept separate for audit
│       └── outputs.tf
└── modules/              # reusable building blocks
    ├── resource_group
    ├── identity          # user-assigned managed identity
    ├── container_registry
    ├── key_vault         # JWT signing private key as PKCS#8 PEM secret
    ├── storage           # data + eh-checkpoints blob containers
    ├── event_hub
    ├── cosmos_db
    ├── log_analytics
    ├── container_app_env # platform-managed network (no VNet integration)
    └── container_app     # supports http_scale_rule + custom_scale_rule
```
## Conventions

- **Provider versions**: `azurerm` pinned to `4.74.0`.
- **Tags**: every resource carries `Environment = "Training"` and `ManagedBy = "Terraform"`.
- **Authentication**: SAS / shared access keys / Cosmos primary keys are all
  disabled. Every service authenticates with its user-assigned managed
  identity and minimum-privilege RBAC.
- **Cost**: smallest SKUs everywhere — ACR Basic, Storage LRS, Event Hubs
  Standard (Basic doesn't support custom consumer groups), Cosmos free tier
  with 1000 RU/s, Container Apps Consumption scale-to-zero, Key Vault
  Standard.

## Step-by-step

### 0. Prerequisites

- Azure CLI logged in: `az login`
- Correct subscription selected: `az account set --subscription <id>`
- Terraform >= 1.6 in PATH

### 1. Bootstrap the state backend (run once per subscription)

**Skip this step entirely if you already have a Storage Account + Blob
Container you want to reuse.** Bootstrap only creates RG + Storage Account +
Container — nothing else. If they exist, go straight to step 2 and edit
`backend.tf` to point at the existing values.

```powershell
cd terraform\bootstrap
terraform init
terraform apply
```

Note the output `storage_account_name` — you need it in step 2.

### 2. Point the env at the backend

Edit `envs\training\backend.tf` with the names of your state backend
resources (either bootstrap's outputs, or your pre-existing ones):

```hcl
backend "azurerm" {
  resource_group_name  = "<state-rg>"
  storage_account_name = "<state-storage>"
  container_name       = "<state-container>"   # must already exist
  key                  = "training.tfstate"
  use_azuread_auth     = true
}
```

The identity running `terraform init` needs **Storage Blob Data Contributor**
on that storage account because `use_azuread_auth = true`.

### 3. Deploy the training environment

```powershell
cd ..\envs\training
copy terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars if you want different prefixes/regions

terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
```

First apply takes ~8–12 minutes (Cosmos and Container Apps env are the slow
ones).

### 4. Push your images, then re-apply with real image refs

```powershell
# get the ACR login server
$acr = terraform output -raw acr_login_server

# log in and push (build commands depend on your service)
az acr login --name $acr.Split('.')[0]

docker tag auth-service:local        $acr/auth-service:0.1.0
docker tag report-service:local      $acr/report-service:0.1.0
docker tag data-ingest-service:local $acr/data-ingest-service:0.1.0

docker push $acr/auth-service:0.1.0
docker push $acr/report-service:0.1.0
docker push $acr/data-ingest-service:0.1.0
```

Then set the image variables in `terraform.tfvars` and re-apply:

```hcl
auth_service_image   = "<acr>/auth-service:0.1.0"
report_service_image = "<acr>/report-service:0.1.0"
data_ingest_image    = "<acr>/data-ingest-service:0.1.0"
```

```powershell
terraform apply
```

### 5. Tear everything down

```powershell
cd terraform\envs\training
terraform destroy

cd ..\..\bootstrap
terraform destroy   # only after every env using this backend is gone
```

## Role assignments at a glance

| Identity    | Role                                   | Scope                                                          |
|-------------|----------------------------------------|----------------------------------------------------------------|
| `mi_auth`   | `AcrPull`                              | ACR                                                            |
| `mi_auth`   | `Key Vault Secrets User`               | `auth-jwt-signing-key` secret (versionless)                    |
| `mi_report` | `AcrPull`                              | ACR                                                            |
| `mi_report` | `Storage Blob Data Contributor`        | `reports` blob container                                       |
| `mi_report` | `Azure Event Hubs Data Sender`         | Event Hub                                                      |
| `mi_ingest` | `AcrPull`                              | ACR                                                            |
| `mi_ingest` | `Azure Event Hubs Data Receiver`       | Event Hub                                                      |
| `mi_ingest` | `Storage Blob Data Contributor`        | `eh-checkpoints` blob container (checkpoint store + KEDA scaler) |
| `mi_ingest` | `Cosmos DB Built-in Data Contributor`* | Cosmos account                                                 |

`*` — Cosmos data-plane role, assigned via `azurerm_cosmosdb_sql_role_assignment`
(distinct from ARM RBAC).

## Autoscaling

| Service               | Scaler                                         | Behaviour                                                                          |
|-----------------------|------------------------------------------------|------------------------------------------------------------------------------------|
| `report-service`      | KEDA built-in `http_scale_rule`                | Scale up at `report_http_concurrent_requests` concurrent reqs; scale to 0 when idle |
| `data-ingest-service` | KEDA `azure-eventhub` `custom_scale_rule`      | Scale up by unprocessed-event lag (read from the `eh-checkpoints` blob container via `mi_ingest`); scale to 0 once lag clears. Max replicas capped at the hub's partition count |

Both scalers authenticate via the per-service user-assigned managed identity
(`identity_id` on the scale rule). No connection strings, no SAS.

## Grafana Alloy sidecar

`enable_grafana_alloy_sidecar = true` adds a `grafana/alloy:latest` container
to `report-service` and `data-ingest-service`. **The sidecar will not collect
anything useful until you also wire in an Alloy config file** — typically via
a Container App secret mounted as a volume. That config delivery is out of
scope for this scaffold; the variable is wired up so you can extend later.

## Known limitations (intentional for training)

- Storage / Event Hubs / Cosmos have `public_network_access_enabled = true`.
  Production would put them behind private endpoints in the VNet.
- Key Vault uses `purge_protection_enabled = false` and a 7-day soft-delete so
  you can `destroy` repeatedly without polluting the soft-deleted vault list.
- auth-service reads the RSA private key as a PKCS#8 PEM secret from Key
  Vault (resource `tls_private_key.jwt_signing` + `azurerm_key_vault_secret`).
  The key persists across restarts, so the JWKS kid stays stable. To rotate,
  taint `module.key_vault.tls_private_key.jwt_signing`.
- No `terraform.tfvars` is committed — `terraform.tfvars.example` is the
  template.

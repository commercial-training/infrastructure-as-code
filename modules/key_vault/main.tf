data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.sku_name
  rbac_authorization_enabled    = true
  purge_protection_enabled      = false
  soft_delete_retention_days    = 7
  public_network_access_enabled = true
  tags                          = var.tags
}

# Grant the deploying principal Key Vault Secrets Officer so the secret resource
# below can be created. RBAC-mode KV denies secret operations even to the
# subscription owner without this.
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# RSA private key in PKCS#8 PEM form. The Java auth-service parses this via
# KeyFactory.generatePrivate(new PKCS8EncodedKeySpec(...)) and derives the
# matching public key from the CRT components for JWKS.
resource "tls_private_key" "jwt_signing" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "azurerm_key_vault_secret" "jwt_signing" {
  name         = var.secret_name
  key_vault_id = azurerm_key_vault.this.id
  value        = tls_private_key.jwt_signing.private_key_pem_pkcs8
  content_type = "application/x-pem-file"

  depends_on = [azurerm_role_assignment.deployer_secrets_officer]
}

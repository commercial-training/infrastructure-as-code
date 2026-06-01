variable "name" {
  type        = string
  description = "Storage account name (3-24 lowercase alphanumeric, globally unique)."
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "data_container_name" {
  type        = string
  default     = "reports"
  description = "Blob container that report-service writes payloads into. Source app default is `reports`."
}

variable "checkpoint_container_name" {
  type        = string
  default     = "eh-checkpoints"
  description = "Blob container used by data-ingest-service's BlobCheckpointStore (and the KEDA azure-eventhub scaler) to persist consumer offsets."
}

variable "tags" {
  type    = map(string)
  default = {}
}

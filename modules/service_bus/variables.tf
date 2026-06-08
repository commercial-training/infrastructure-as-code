variable "capacity" {
  description = "Messaging unit capacity for Premium namespaces. Ignored for Basic and Standard."
  type        = number
  default     = 1
}

variable "default_message_ttl" {
  description = "ISO 8601 duration for the default time-to-live of queue messages."
  type        = string
  default     = "P14D"
}

variable "duplicate_detection_history_time_window" {
  description = "ISO 8601 duration during which duplicate message IDs can be detected."
  type        = string
  default     = "PT10M"
}

variable "location" {
  description = "Azure region for the Service Bus namespace."
  type        = string
}

variable "lock_duration" {
  description = "ISO 8601 duration for the peek-lock held by a receiver."
  type        = string
  default     = "PT1M"
}

variable "max_delivery_count" {
  description = "Number of failed deliveries before a message is moved to the dead-letter queue."
  type        = number
  default     = 10
}

variable "namespace_name" {
  description = "Globally unique Service Bus namespace name."
  type        = string
}

variable "partitioning_enabled" {
  description = "Whether to partition the queue across multiple message brokers. Only applies at queue creation."
  type        = bool
  default     = true
}

variable "queue_name" {
  description = "Service Bus queue name used for report data events."
  type        = string
  default     = "data-events"
}

variable "requires_duplicate_detection" {
  description = "Whether the queue rejects duplicate message IDs within the detection window."
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "Resource group that contains the Service Bus namespace."
  type        = string
}

variable "sku" {
  description = "Service Bus namespace SKU."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "Service Bus SKU must be Basic, Standard, or Premium."
  }
}

variable "tags" {
  description = "Tags to assign to Service Bus resources."
  type        = map(string)
  default     = {}
}

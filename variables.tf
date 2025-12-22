variable "cloud_id" {
  type        = string
  description = "Yandex Cloud Cloud ID"
}

variable "folder_id" {
  type        = string
  description = "Yandex Cloud Folder ID"
}

variable "zone" {
  type        = string
  description = "Yandex Cloud availability zone"
  default     = "ru-central1-d"
}

variable "service_account_key_file" {
  type        = string
  description = "Path to the service account key file for Yandex Cloud provider authentication"
}

variable "tg_bot_key" {
  type        = string
  description = "Telegram Bot API token"
  sensitive   = true
}

variable "ymq_access_key" {
  type        = string
  description = "Static key for Yandex Message Queue"
  sensitive   = true
}

variable "ymq_secret_key" {
  type        = string
  description = "Secret key for Yandex Message Queue"
  sensitive   = true
}

variable "storage_access_key" {
  type        = string
  description = "Static key for Yandex Object Storage"
  sensitive   = true
}

variable "storage_secret_key" {
  type        = string
  description = "Secret key for Yandex Object Storage"
  sensitive   = true
}
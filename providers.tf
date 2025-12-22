terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.175.0"
    }
    telegram = {
      source = "yi-jiayu/telegram"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
  service_account_key_file = var.service_account_key_file
}

provider "telegram" {
  bot_token = var.tg_bot_key
}
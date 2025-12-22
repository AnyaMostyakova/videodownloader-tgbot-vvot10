locals {
  prefix = "vvot10"
}

resource "yandex_message_queue" "queue_receiver" {
  name       = "${local.prefix}-queue-receiver"
  access_key = "YCAJEphyjwBmMc1b9Vn6r1DEB"
  secret_key = "YCMtM6xBGsOr2T3RVSEAy9tCEdm50_TsV8pB42pG"
}

resource "yandex_message_queue" "queue_downloader" {
  name       = "${local.prefix}-queue-downloader"
  access_key = "YCAJEphyjwBmMc1b9Vn6r1DEB"
  secret_key = "YCMtM6xBGsOr2T3RVSEAy9tCEdm50_TsV8pB42pG"
}

resource "yandex_storage_bucket" "bucket" {
  bucket     = "vvot10-tg-video"
  access_key = "YCAJEphyjwBmMc1b9Vn6r1DEB"     
  secret_key = "YCMtM6xBGsOr2T3RVSEAy9tCEdm50_TsV8pB42pG" 
}

data "archive_file" "receiver_zip" {
  type        = "zip"
  source_dir  = "${path.module}/functions/receiver"
  output_path = "${path.module}/build/receiver.zip"
}

data "archive_file" "downloader_zip" {
  type        = "zip"
  source_dir  = "${path.module}/functions/downloader"
  output_path = "${path.module}/build/downloader.zip"
}

resource "yandex_function" "func_receiver" {
  name               = "${local.prefix}-func-receiver"
  description        = "Handles incoming Telegram updates"
  runtime            = "python311"
  entrypoint         = "index.handler"
  memory             = 128
  execution_timeout  = 10
  service_account_id = "aje8krpkjdmjihbrrdo4"
  user_hash          = data.archive_file.receiver_zip.output_base64sha256

  environment = {
    TG_TOKEN             = var.tg_bot_key
    DOWNLOADER_QUEUE_URL = yandex_message_queue.queue_downloader.id
    AWS_ACCESS_KEY_ID = var.ymq_access_key
    AWS_SECRET_ACCESS_KEY = var.ymq_secret_key
  }

  content {
    zip_filename = data.archive_file.receiver_zip.output_path
  }
}

resource "yandex_function" "func_downloader" {
  name               = "${local.prefix}-func-downloader"
  description        = "Downloads video from Telegram and stores it"
  runtime            = "python311"
  entrypoint         = "index.handler"
  memory             = 256
  execution_timeout  = 60
  service_account_id = "aje8krpkjdmjihbrrdo4"
  user_hash          = data.archive_file.downloader_zip.output_base64sha256

  environment = {
    TG_TOKEN = var.tg_bot_key
    BUCKET   = yandex_storage_bucket.bucket.bucket
    API_BASE = "https://${yandex_api_gateway.api.domain}"
    AWS_ACCESS_KEY_ID = var.storage_access_key
    AWS_SECRET_ACCESS_KEY = var.storage_secret_key
  }

  content {
    zip_filename = data.archive_file.downloader_zip.output_path
  }
}

resource "yandex_function_trigger" "trigger_receiver" {
  name = "${local.prefix}-trigger-receiver"

  message_queue {
    queue_id           = yandex_message_queue.queue_receiver.arn
    service_account_id = "aje8krpkjdmjihbrrdo4"
    batch_cutoff       = 10
    batch_size         = 1
  }

  function {
    id                 = yandex_function.func_receiver.id
    service_account_id = "aje8krpkjdmjihbrrdo4"
  }
}

resource "yandex_function_trigger" "trigger_downloader" {
  name = "${local.prefix}-trigger-downloader"

  message_queue {
    queue_id           = yandex_message_queue.queue_downloader.arn
    service_account_id = "aje8krpkjdmjihbrrdo4"
    batch_cutoff       = 10
    batch_size         = 1
  }

  function {
    id                 = yandex_function.func_downloader.id
    service_account_id = "aje8krpkjdmjihbrrdo4"
  }
}

data "template_file" "openapi_spec" {
  template = file("${path.module}/openapi.yaml")
  vars = {
    receiver_function_id = yandex_function.func_receiver.id
    bucket_name          = yandex_storage_bucket.bucket.bucket
    sa_id                = "aje8krpkjdmjihbrrdo4"
  }
}

resource "yandex_api_gateway" "api" {
  name        = "${local.prefix}-api"
  description = "API Gateway for Telegram bot"
  spec        = data.template_file.openapi_spec.rendered
}

resource "telegram_bot_webhook" "webhook" {
  url = "https://${yandex_api_gateway.api.domain}/webhook"
}

output "api_gateway_domain" {
  value = yandex_api_gateway.api.domain
}

output "webhook_url" {
  value = "https://${yandex_api_gateway.api.domain}/webhook"
}

output "bucket_name" {
  value = yandex_storage_bucket.bucket.bucket
}

resource "yandex_resourcemanager_folder_iam_binding" "ymq_writer" {
  folder_id = var.folder_id
  role      = "ymq.writer"

  members = [
    "serviceAccount:aje8krpkjdmjihbrrdo4"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "ymq_reader" {
  folder_id = var.folder_id
  role      = "ymq.reader"

  members = [
    "serviceAccount:aje8krpkjdmjihbrrdo4"
  ]
}

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.140.0"
    }
  }
  required_version = ">= 1.6.0"
}

provider "yandex" {
  zone      = var.yc_zone
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
}

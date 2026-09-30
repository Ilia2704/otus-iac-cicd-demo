variable "yc_zone" {
  description = "Yandex Cloud availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "yc_folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "yc_cloud_id" {
  description = "Yandex Cloud cloud ID"
  type        = string
}

variable "yc_token" {
  description = "Yandex Cloud OAuth token (demo only)"
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  description = "Globally unique Yandex Object Storage bucket name"
  type        = string
}

variable "ssh_public_key" {
  description = "Public SSH key content for ubuntu user"
  type        = string
}

variable "disk_params" {
  description = "Boot disk parameters"
  type = object({
    name    = string
    type    = string
    size_gb = number
  })
  default = {
    name    = "otus-qwen-disk"
    type    = "network-ssd"
    size_gb = 30
  }
}

variable "ubuntu_image_family" {
  description = "Ubuntu image family used for the VM"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "vm_name" {
  type    = string
  default = "otus-qwen-vm"
}

variable "platform_id" {
  type    = string
  default = "standard-v3"
}

variable "vm_cores" {
  type    = number
  default = 4
}

variable "vm_memory_gb" {
  type    = number
  default = 8
}

variable "sa_name" {
  type    = string
  default = "otus-storage-editor"
}

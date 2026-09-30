data "yandex_compute_image" "ubuntu" {
  family = var.ubuntu_image_family
}

resource "yandex_compute_disk" "disk" {
  name     = var.disk_params.name
  type     = var.disk_params.type
  image_id = data.yandex_compute_image.ubuntu.id
  zone     = var.yc_zone
  size     = var.disk_params.size_gb
}

resource "yandex_vpc_network" "network" {
  name = "otus-qwen-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "otus-qwen-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}

resource "yandex_vpc_security_group" "vm" {
  name       = "otus-qwen-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Sentiment API"
    port           = 8000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Outbound internet for Docker/Ollama model pull"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_compute_instance" "vm" {
  name        = var.vm_name
  platform_id = var.platform_id
  zone        = var.yc_zone

  resources {
    cores  = var.vm_cores
    memory = var.vm_memory_gb
  }

  boot_disk {
    disk_id = yandex_compute_disk.disk.id
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.vm.id]
  }

  metadata = {
    ssh-keys  = "ubuntu:${var.ssh_public_key}"
    user-data = file("${path.module}/cloud-init.yaml")
  }
}

resource "yandex_iam_service_account" "sa" {
  name        = var.sa_name
  description = "Service Account for OTUS Terraform course"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_role" {
  folder_id = var.yc_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Static access key for Object Storage"
  depends_on         = [yandex_resourcemanager_folder_iam_member.sa_role]
}

resource "yandex_storage_bucket" "bucket" {
  bucket     = var.bucket_name
  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
}

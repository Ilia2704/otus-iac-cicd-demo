output "vm_external_ip" {
  value       = yandex_compute_instance.vm.network_interface[0].nat_ip_address
  description = "Public IP of the Yandex Compute VM"
}

output "bucket_name" {
  value       = yandex_storage_bucket.bucket.bucket
  description = "Object Storage bucket created by Terraform"
}

output "service_account_id" {
  value       = yandex_iam_service_account.sa.id
  description = "Storage service account ID"
}

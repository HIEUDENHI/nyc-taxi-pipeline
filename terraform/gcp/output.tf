output "service_account_key" {
  value     = base64decode(google_service_account_key.service_account_key.private_key)
  sensitive = true
}
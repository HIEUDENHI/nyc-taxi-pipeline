terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "tls" {}

provider "local" {}

# 1. Tạo Service Account
resource "google_service_account" "service_account" {
  project      = var.project_id
  account_id   = var.account_id
  display_name = "NYC Taxi Pipeline Service Account"
}

# 2. Tạo JSON Key (TYPE_JSON_FILE)
resource "google_service_account_key" "service_account_key" {
  service_account_id = google_service_account.service_account.name
}

# 3. Ghi JSON credentials ra file service-account.json
resource "local_file" "sa_key_json" {
  content         = base64decode(google_service_account_key.service_account_key.private_key)
  filename        = "${path.module}/service-account.json"
  file_permission = "0600"
}

# 4. Gán IAM role cho Service Account
resource "google_project_iam_binding" "service_account_binding" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

# 5. (Giữ nguyên) Sinh SSH key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key_pem" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "./ssh/nyc-taxi-pipeline.pem"
  file_permission = "0600"
}

variable "project_id" {
  description = "Google project ID"
  type        = string
}

variable "account_id" {
  description = "Service account ID"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
}

variable "zone" {
  description = "Zone"
  type        = string
}

variable "gce_name" {
  description = "GCE instance name"
  type        = string
}

variable "storage_class" {
  description = "Storage class"
  type        = string
}

variable "data_lake_bucket" {
  description = "Data lake bucket name"
  type        = string
}

variable "raw_bq_dataset" {
  description = "Raw BigQuery dataset"
  type        = string
}

variable "dev_bq_dataset" {
  description = "Development BigQuery dataset"
  type        = string
}

variable "prod_bq_dataset" {
  description = "Production BigQuery dataset"
  type        = string
}
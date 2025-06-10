resource "google_bigquery_dataset" "bronze" {
  dataset_id = var.raw_bq_dataset
  project    = var.project_id
  location   = var.region
}

resource "google_bigquery_dataset" "dev_dataset" {
  dataset_id                 = var.dev_bq_dataset
  project                    = var.project_id
  location                   = var.region
  delete_contents_on_destroy = true
}

resource "google_bigquery_dataset" "prod_dataset" {
  dataset_id                 = var.prod_bq_dataset
  project                    = var.project_id
  location                   = var.region
  delete_contents_on_destroy = true
}


// gcp/terraform.tfvars
project_id = "nyc-taxi-pipeline-460408" # Replace with your project ID
region     = "US"
zone       = "US"
account_id         = "sa-nyc-taxi-pipeline"
gce_name           = "vm-nyc-taxi"
storage_class      = "STANDARD"
data_lake_bucket   = "nyc-taxi-landing"
raw_bq_dataset     = "nyc_taxi_raw"
dev_bq_dataset     = "dev_taxi_data"
prod_bq_dataset    = "prod_taxi_data"
from airflow import DAG
from airflow.utils.trigger_rule import TriggerRule
from airflow.operators.bash import BashOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.models.param import Param
from datetime import datetime, timedelta

GCS_BUCKET      = "taxi-data-lake_nyc-taxi-pipeline-460408"
DBT_PROJECT_DIR = "/usr/local/airflow/include/dbt"
DBT_TARGET      = "dev"
PROJECT_ID      = "nyc-taxi-pipeline-460408" 

DEFAULT_ARGS = {
    "owner": "data_engineer",
    "retries": 2,
    "retry_delay": timedelta(minutes=10),
}

with DAG(
    dag_id              = "monthly_taxi_pipeline",
    description         = "Ingest monthly NYC Taxi (green & yellow) + build marts with dbt",
    start_date          = datetime(2024, 1, 1),
    schedule_interval   = "@monthly",
    catchup             = True,
    max_active_runs     = 1,
    default_args        = DEFAULT_ARGS,
    tags                = ["nyc-taxi", "dbt", "bigquery"],
    params = {
        "run_month": Param(
            default     = "",
            type        = "string",
            pattern     = r"^(\d{4}-\d{2})?$",
        )
    },
) as dag:

  
    

    load_yellow_to_bq = BigQueryInsertJobOperator(
        task_id = "load_yellow_to_bq",
        configuration = {
            "load": {
                "sourceUris": [
                    "gs://{{ params.bucket }}/nyc-taxi-landing/yellow/"
                    "year={{ (params.run_month or ds)[:4] }}/"
                    "month={{ (params.run_month or ds)[5:7] }}/"
                    "yellow_tripdata_{{ params.run_month or ds[:7] }}.parquet"
                ],
                "destinationTable": {
                    "projectId": "{{ params.project_id }}",
                    "datasetId": "nyc_taxi_raw",
                    "tableId": "yellow_trips"
                },
                "writeDisposition": "WRITE_TRUNCATE",
                "sourceFormat":     "PARQUET",
                "autodetect":       False,
                "timePartitioning": {
                    "type": "MONTH",
                    "field": "tpep_pickup_datetime"
                }
            }
        },
        gcp_conn_id = "gcp",
        params = {
            "bucket":     GCS_BUCKET,
            "project_id": PROJECT_ID,
        },
    )

    load_green_to_bq = BigQueryInsertJobOperator(
        task_id = "load_green_to_bq",
        configuration = {
            "load": {
                "sourceUris": [
                    "gs://{{ params.bucket }}/nyc-taxi-landing/green/"
                    "year={{ (params.run_month or ds)[:4] }}/"
                    "month={{ (params.run_month or ds)[5:7] }}/"
                    "green_tripdata_{{ params.run_month or ds[:7] }}.parquet"
                ],
                "destinationTable": {
                    "projectId": "{{ params.project_id }}",
                    "datasetId": "nyc_taxi_raw",
                    "tableId": "green_trips"
                },
                "writeDisposition": "WRITE_TRUNCATE",
                "sourceFormat":     "PARQUET",
                "autodetect":       False,
                "timePartitioning": {
                    "type": "MONTH",
                    "field": "lpep_pickup_datetime"
                }
            }
        },
        gcp_conn_id = "gcp",
        params = {
            "bucket":     GCS_BUCKET,
            "project_id": PROJECT_ID,
        },
    )

    dbt_run = BashOperator(
        task_id      = "dbt_run",
        bash_command = (
            f"dbt run --project-dir {DBT_PROJECT_DIR} "
            f"--profiles-dir {DBT_PROJECT_DIR} "
            f"--target {DBT_TARGET} "
            "--select tag:core+ tag:staging+ "
            '--vars \'{"load_month":"{{ params.run_month or ds[:7] }}"}\''
        ),
    )

    dbt_test = BashOperator(
        task_id      = "dbt_test",
        bash_command = (
            f"dbt test --project-dir {DBT_PROJECT_DIR} "
            f"--profiles-dir {DBT_PROJECT_DIR} "
            f"--target {DBT_TARGET} "
            '--vars \'{"load_month":"{{ params.run_month or ds[:7] }}"}\''
        ),
        trigger_rule = TriggerRule.ALL_DONE,
    )

    [load_yellow_to_bq, load_green_to_bq] >> dbt_run >> dbt_test

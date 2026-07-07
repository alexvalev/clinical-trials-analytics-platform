from airflow import DAG
from airflow.providers.databricks.operators.databricks import DatabricksSubmitRunOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {
    "owner": "alexvalev",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

DBT_PROJECT_DIR = "/mnt/c/Users/User/clinical-trials-analytics-platform/dbt/clinical_trials"
DBT_VENV_ACTIVATE = "source ~/dbt-venv/bin/activate"

NOTEBOOK_BASE_PATH = "/Workspace/Users/alexvalev29@gmail.com/Clinical-trials-project"

with DAG(
    dag_id="clinical_trials_pipeline",
    description="End-to-end clinical trials pipeline: Bronze, Silver, dbt, ML training",
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    default_args=default_args,
    tags=["clinical_trials", "databricks", "dbt", "portfolio"],
) as dag:

    bronze_ingestion = DatabricksSubmitRunOperator(
        task_id="bronze_ingestion",
        databricks_conn_id="databricks_default",
        tasks=[
            {
                "task_key": "bronze_ingestion_task",
                "notebook_task": {"notebook_path": f"{NOTEBOOK_BASE_PATH}/01_bronze_ingestion"},
            }
        ],
    )

    silver_transformation = DatabricksSubmitRunOperator(
        task_id="silver_transformation",
        databricks_conn_id="databricks_default",
        tasks=[
            {
                "task_key": "silver_transformation_task",
                "notebook_task": {"notebook_path": f"{NOTEBOOK_BASE_PATH}/02_silver_transformation"},
            }
        ],
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"{DBT_VENV_ACTIVATE} && cd {DBT_PROJECT_DIR} && dbt run",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"{DBT_VENV_ACTIVATE} && cd {DBT_PROJECT_DIR} && dbt test",
    )

    ml_training = DatabricksSubmitRunOperator(
        task_id="ml_training",
        databricks_conn_id="databricks_default",
        tasks=[
            {
                "task_key": "ml_training_task",
                "notebook_task": {"notebook_path": f"{NOTEBOOK_BASE_PATH}/04_ml_prediction"},
            }
        ],
    )

    bronze_ingestion >> silver_transformation >> dbt_run >> dbt_test >> ml_training

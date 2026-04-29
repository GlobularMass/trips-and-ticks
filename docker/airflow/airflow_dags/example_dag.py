"""
Example Apache Airflow DAG

This is a simple example DAG that demonstrates:
- Creating a DAG with basic tasks
- Using BashOperator and PythonOperator
- Task dependencies
- Scheduling

Place this file in the airflow_dags/ folder with a .py extension.
DAG filename must not contain hyphens; underscores are preferred.
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

# Define default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
    'start_date': datetime(2024, 1, 1),
}

# Define the DAG
dag = DAG(
    'example_dag',
    default_args=default_args,
    description='Example DAG for Airflow',
    schedule_interval='@daily',  # Run daily
    catchup=False,  # Don't backfill missed runs
    tags=['example'],
)

# Define Python functions for tasks
def print_hello():
    """Simple Python function that prints a message"""
    return 'Hello from Airflow!'

def print_context(**context):
    """Python function that prints execution context"""
    print(f"Execution date: {context['execution_date']}")
    print(f"Task: {context['task'].task_id}")
    return 'Task context printed'

# Define tasks
task_1 = PythonOperator(
    task_id='hello_task',
    python_callable=print_hello,
    dag=dag,
)

task_2 = BashOperator(
    task_id='bash_task',
    bash_command='echo "Hello from bash task!"',
    dag=dag,
)

task_3 = PythonOperator(
    task_id='context_task',
    python_callable=print_context,
    provide_context=True,
    dag=dag,
)

task_4 = BashOperator(
    task_id='date_task',
    bash_command='date',
    dag=dag,
)

# Set task dependencies (define execution order)
# task_1 must complete before task_2 and task_3
task_1 >> [task_2, task_3]
# task_3 must complete before task_4
task_3 >> task_4

# You can also use:
# task_1.set_downstream(task_2)
# task_1.set_upstream(task_3)

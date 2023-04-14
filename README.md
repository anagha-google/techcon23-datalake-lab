# Data Lake Lab for TechCon 2023

## About the lab

This lab demonstrates integration of structured data in Cloud Storage into BigQuery with a minimum viable example of a CSV file containing Chicago crimes reference data into BigQuery from where we will run a crime trend report. The technology and product used to integrate are Apache Spark on Dataproc Serverless Batch. We will use a readily available Dataproc (integration) template (quickstart/solution accelerator) for the integration that does not require code authoring, just integration configuration. 

This lab is intended to be a gentle introduction to Dataproc for the BigQuery savvy user base that aspire to ease into open data analytics on Google Cloud Platform.

<hr>

## Lab Solution Architecture

![README](01-images/datalake-lab-architecture.png)   
<br><br>

<hr>

## About Dataproc Serverless Spark 

Dataproc Serverless Spark is a fully managed, autoscalable, zero ops, secure Spark as a service for data engineering and machine learning at scale. It offers a zero resource contention, democratized spark experience - accelerating developer productivity and speed to production. Learn more at - https://cloud.google.com/dataproc-serverless/docs 

<hr>


## About Dataproc Templates

Dataproc templates is an Apache Spark based, code-free solution to execute simple, but large, cloud data tasks, including data import/export/backup/restore and bulk API operations. Dataproc templates offers scale through parallelism natively available with Apache Spark, simplicity of management/zero ops through Dataproc's Serverless Spark feature (with autoscaling by default) and speed to production with its simplicity - no code, just configuration.

There are a variety of generally available templates that integrate disparate systems. Learn more at: https://github.com/GoogleCloudPlatform/dataproc-templates

<hr>


## Lab Module 1: Data Integration with Cloud Dataproc

### 1.1. Walk through of environment




### 1.2. Integration execution

Documentation for just FYI: 
https://cloud.google.com/dataproc-serverless/docs/templates/storage-to-bigquery#storage_to_bigquery_sample-gcloud
<br>

#### 1.2.1. Run the integration process

Paste and run in Cloud Shell-
```
REGION="us-central1"
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $GCP_PROJECT | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
SUBNET="lab-snet"
DATA_SOURCE_GCS_URI="gs://data-${PROJECT_NBR}/"
BQ_DATASET_NM="crimes_ds"
BQ_TABLE_NM="chicago_iucr_ref"
SCRATCH_BUCKET_NM="lab-spark-bucket-${PROJECT_NBR}"
UMSA_FQN="lab-sa@$PROJECT_ID.iam.gserviceaccount.com"


gcloud dataproc batches submit spark \
    --class=com.google.cloud.dataproc.templates.main.DataProcTemplate \
    --version="1.1" \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --jars="gs://dataproc-templates-binaries/latest/java/dataproc-templates.jar" \
    --subnet="$SUBNET" \
    --service-account="$UMSA_FQN" \
    --batch="techcon-datalake-lab-$RANDOM" \
    -- --template=GCSTOBIGQUERY \
    --templateProperty log.level="INFO" \
    --templateProperty project.id="$PROJECT_ID" \
    --templateProperty gcs.bigquery.input.location="$DATA_SOURCE_GCS_URI" \
    --templateProperty gcs.bigquery.input.format="csv" \
    --templateProperty gcs.bigquery.output.dataset="$BQ_DATASET_NM" \
    --templateProperty gcs.bigquery.output.table="$BQ_TABLE_NM" \
    --templateProperty gcs.bigquery.temp.bucket.name="$SCRATCH_BUCKET_NM" 
 
```

![README](01-images/techcon-lab-00.png)   
<br><br>

### 1.2. Monitor the integration execution

1. Navigate to the Dataproc UI->Batches in the Cloud Console

![README](01-images/techcon-lab-01.png)   
<br><br>

2. Click on the batch job link displayed

![README](01-images/techcon-lab-02.png)   
<br><br>



### 1.3. Validation of integration operation


## Lab Module 2: Data Analysis with BigQuery




## Housekeeping

Shut down your GCP project to avoid billing.

<hr>



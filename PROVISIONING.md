# Provisioning Automation

The following are instructions to provision the environment with Terraform.

## 1. Clone the repo

Launch Cloud Shell scoped to the project and paste and run the below-
```
git clone https://github.com/anagha-google/techcon23-datalake-lab.git
```


## 2. Declare variables

Paste and run the below variables in Cloud Shell-
```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`

YOUR_USER_PRINCIPAL_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
ORG_ID=`gcloud organizations list --format="value(name)"`
```

## 2. Initialize Terraform

Paste and run the below  in Cloud Shell-
```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`

YOUR_USER_PRINCIPAL_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
ORG_ID=`gcloud organizations list --format="value(name)"`
```

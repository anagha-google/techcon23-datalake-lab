variable "project_id" {
  type        = string
  description = "project id required"
}

variable "project_number" {
 type        = string
 description = "project number in which demo deploy"
}

variable "user_principal_name" {
 description = "Your GCP user ID"
}

variable "org_id" {
 description = "Organization ID in which project created"
}

variable "bq_region" {
 description = "BQ multi-region"
 default = "US"
}

variable "dataproc_region" {
 description = "GCP region for Dataproc"
 default = "us-central1"
}


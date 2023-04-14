/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/******************************************
Local variables declaration
 *****************************************/

locals {
project_id                  = "${var.project_id}"
project_nbr                 = "${var.project_number}"
admin_upn_fqn               = "${var.user_principal_name}"
bq_region                   = "${var.bq_region}"
dataproc_region             = "${var.dataproc_region}"
umsa                        = "lab-sa"
umsa_fqn                    = "${local.umsa}@${local.project_id}.iam.gserviceaccount.com"

lab_spark_bucket            = "lab-spark-bucket-${local.project_nbr}"
lab_spark_bucket_fqn        = "gs://lab-spark-${local.project_nbr}"
lab_vpc_nm                  = "lab-vpc-${local.project_nbr}"
lab_subnet_nm               = "lab-snet"
lab_subnet_cidr             = "10.0.0.0/16"

lab_data_bucket             = "data-${local.project_nbr}"
lab_code_bucket             = "code-${local.project_nbr}"
 
bq_datamart_ds              = "crimes_ds"

}

/******************************************
1. Enable Google APIs in parallel
 *****************************************/

 module "activate_service_apis" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  project_id                     = var.project_id
  enable_apis                 = true

  activate_apis = [
    "compute.googleapis.com",
    "dataproc.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "storage-component.googleapis.com",
    "bigquerystorage.googleapis.com",
    "bigquery.googleapis.com" ,
    "cloudresourcemanager.googleapis.com",
    "orgpolicy.googleapis.com"
    ]

  disable_services_on_destroy = false
}
/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/

resource "time_sleep" "sleep_after_activate_service_apis" {
  create_duration = "60s"

  depends_on = [
    module.activate_service_apis
  ]
}

/******************************************
2. Project-scoped Org Policy Updates
*****************************************/

resource "google_project_organization_policy" "bool-policies" {
  for_each = {
    "compute.requireOsLogin" : false,
    "compute.disableSerialPortLogging" : false,
    "compute.requireShieldedVm" : false
  }
  project    = var.project_id
  constraint = format("constraints/%s", each.key)
  boolean_policy {
    enforced = each.value
  }

  depends_on = [
    time_sleep.sleep_after_activate_service_apis
  ]

}

resource "google_project_organization_policy" "list_policies" {
  for_each = {
    "compute.vmCanIpForward" : true,
    "compute.vmExternalIpAccess" : true,
    "compute.restrictVpcPeering" : true
  }
  project     = var.project_id
  constraint = format("constraints/%s", each.key)
  list_policy {
    allow {
      all = each.value
    }
  }

  depends_on = [
    time_sleep.sleep_after_activate_service_apis
  ]

}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_apis_and_org_policies" {
  create_duration = "60s"

  depends_on = [
    google_project_organization_policy.bool-policies,
    google_project_organization_policy.list_policies,
    time_sleep.sleep_after_activate_service_apis
  ]
}

/******************************************
3. Create User Managed Service Account 
 *****************************************/
module "umsa_creation" {
  source     = "terraform-google-modules/service-accounts/google"
  project_id = local.project_id
  names      = ["${local.umsa}"]
  display_name = "User Managed Service Account"
  description  = "User Managed Service Account for Dataplex lab"
   depends_on = [time_sleep.sleep_after_apis_and_org_policies]
}

/******************************************
4a. Grant IAM roles to User Managed Service Account
 *****************************************/

module "umsa_role_grants" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = "${local.umsa_fqn}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [
    
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/storage.objectAdmin",
    "roles/storage.admin",
    "roles/dataproc.worker",
    "roles/dataproc.editor",
    "roles/bigquery.dataEditor",
    "roles/bigquery.admin"
  ]
  depends_on = [
    module.umsa_creation
  ]
}




/******************************************************
5. Grant Service Account Impersonation privilege to yourself/Admin User
 ******************************************************/

module "umsa_impersonate_privs_to_admin" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam/"
  service_accounts = ["${local.umsa_fqn}"]
  project          = local.project_id
  mode             = "additive"
  bindings = {
    "roles/iam.serviceAccountUser" = [
      "user:${local.admin_upn_fqn}"
    ],
    "roles/iam.serviceAccountTokenCreator" = [
      "user:${local.admin_upn_fqn}"
    ]

  }
  depends_on = [
    module.umsa_creation
  ]
}



/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_identities_permissions" {
  create_duration = "120s"
  depends_on = [
    module.umsa_creation,
    module.umsa_role_grants,
    module.umsa_impersonate_privs_to_admin
  ]
}

/************************************************************************
7. Create VPC network & subnet 
 ***********************************************************************/
module "vpc_creation" {
  source                                 = "terraform-google-modules/network/google"
  project_id                             = local.project_id
  network_name                           = local.lab_vpc_nm
  routing_mode                           = "REGIONAL"

  subnets = [
    {
      subnet_name           = "${local.lab_subnet_nm}"
      subnet_ip             = "${local.lab_subnet_cidr}"
      subnet_region         = "${local.dataproc_region}"
      subnet_range          = local.lab_subnet_cidr
      subnet_private_access = true
    }
  ]
  depends_on = [
    time_sleep.sleep_after_identities_permissions
  ]
}


/******************************************
8. Create Firewall rules 
 *****************************************/

resource "google_compute_firewall" "allow_intra_snet_ingress_to_any" {
  project   = local.project_id 
  name      = "allow-intra-snet-ingress-to-any"
  network   = local.lab_vpc_nm
  direction = "INGRESS"
  source_ranges = [local.lab_subnet_cidr]
  allow {
    protocol = "all"
  }
  description        = "Creates firewall rule to allow ingress from within subnet on all ports, all protocols"
  depends_on = [
    module.vpc_creation
  ]
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_network_and_firewall_creation" {
  create_duration = "120s"
  depends_on = [
    module.vpc_creation,
    google_compute_firewall.allow_intra_snet_ingress_to_any
  ]
}

/******************************************
9. Create Storage bucket 
 *****************************************/

resource "google_storage_bucket" "lab_spark_bucket_creation" {
  project                           = local.project_id 
  name                              = local.lab_spark_bucket
  location                          = local.dataproc_region
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_identities_permissions
  ]
}

resource "google_storage_bucket" "lab_data_bucket_creation" {
  project                           = local.project_id 
  name                              = local.lab_data_bucket
  location                          = local.dataproc_region
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_identities_permissions
  ]
}


resource "google_storage_bucket" "lab_code_bucket_creation" {
  project                           = local.project_id 
  name                              = local.lab_code_bucket
  location                          = local.dataproc_region
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [
      time_sleep.sleep_after_identities_permissions
  ]
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/

resource "time_sleep" "sleep_after_bucket_creation" {
  create_duration = "60s"
  depends_on = [
    google_storage_bucket.lab_data_bucket_creation,
    google_storage_bucket.lab_code_bucket_creation
  ]
}

/******************************************
10. Copy of datasets, scripts and notebooks to buckets
 ******************************************/

variable "csv_datasets_to_upload" {
  type = map(string)
  default = {
    "../datasets/chicago-crimes/reference_data/crimes_chicago_iucr_ref.csv"="reference_data/crimes_chicago_iucr_ref.csv"
    }
}

resource "google_storage_bucket_object" "upload_lab_data_to_gcs" {
  for_each = var.csv_datasets_to_upload
  name     = each.value
  source   = "${path.module}/${each.key}"
  bucket   = "${local.lab_data_bucket_raw}"
  depends_on = [
    time_sleep.sleep_after_bucket_creation
  ]
}
 
/******************************************
11. Create a BQ dataset
 ******************************************/
 
resource "google_bigquery_dataset" "bq_dataset_creation" {
  dataset_id                  = local.bq_datamart_ds
  location                    = local.bq_region
}



/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/

resource "time_sleep" "sleep_after_network_and_storage_steps" {
  create_duration = "120s"
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation,
      time_sleep.sleep_after_bucket_creation,
      google_storage_bucket_object.upload_lab_data_to_gcs
  ]
}

/******************************************
DONE
******************************************/

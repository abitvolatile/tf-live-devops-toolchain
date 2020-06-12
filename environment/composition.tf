
//--------------------------------------------------------------------
// Terraform Configuration Parameters

terraform {
  backend "gcs" {
    prefix = "temp"

    # The GCS Bucket name is handled by a variable.
    # Uncomment if you want to statically set this value.
    #bucket = "gcs_bucket_name"
  }
  required_version = "= 0.12.24"
  required_providers {
    google      = "= 2.14"
    google-beta = "= 2.14"
    random      = "~> 2.2"
    http        = ">= 1.1.1"
    kubernetes  = "= 1.11.2"
    helm        = "= 1.2.1"
  }
}




//--------------------------------------------------------------------
// Terraform Providers

provider "google" {
  project = "${var.google_project_base}-${random_id.project_id.hex}"

  scopes = [
    # Default scopes
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",

    # Required for google_client_openid_userinfo
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

provider "google-beta" {
  project = "${var.google_project_base}-${random_id.project_id.hex}"
}

provider "random" {}

provider "http" {}




//--------------------------------------------------------------------
// Prerequisite Resources

resource "random_id" "project_id" {
  byte_length = 3
}

locals {
  google_project_name = "${var.google_project_base}-${random_id.project_id.hex}"
}




//--------------------------------------------------------------------
// Variables

variable "google_billing_account" {}
variable "google_org_id" {}
variable "google_project_base" {}
variable "skip_delete" {}
variable "metadata" {}
variable "google_region" {}
variable "kube_cluster_prefix" {}
variable "kube_cluster_version" {}
variable "kube_nodepool_disk_size" {}
variable "kube_nodepool_instance_type" {}
variable "shared_image_project" {}
variable "jenkins_instance_type" {}
variable "jenkins_data_disk_size" {}
variable "helm_chart_version" {}




//--------------------------------------------------------------------
// Modules

module "public_ip" {
  source  = "app.terraform.io/abitvolatile/public-ip/local"
  version = "~> 1.0"
}


module "project" {
  source  = "app.terraform.io/abitvolatile/project/gcp"
  version = "~> 1.0"

  google_project_name    = local.google_project_name
  google_billing_account = var.google_billing_account
  google_org_id          = var.google_org_id
  metadata               = var.metadata
  skip_delete            = var.skip_delete
}


module "vpc_networking" {
  source  = "app.terraform.io/abitvolatile/vpc-networking/gcp"
  version = "~> 1.0"

  google_project_name = local.google_project_name
}


module "jenkins" {
  source  = "app.terraform.io/abitvolatile/jenkins/gcp"
  version = "~> 1.0"

  google_project_name    = local.google_project_name
  google_compute_network = module.vpc_networking.google_compute_network_name
  google_project_number  = module.project.google_project_number
  google_region          = var.google_region
  local_public_ip        = module.public_ip.public_ip
  shared_image_project   = var.shared_image_project
  jenkins_instance_type  = var.jenkins_instance_type
  jenkins_data_disk_size = var.jenkins_data_disk_size
}


module "gke" {
  source  = "app.terraform.io/abitvolatile/gke/gcp"
  version = "~> 1.0"

  google_project_name         = local.google_project_name
  google_compute_network      = module.vpc_networking.google_compute_network_name
  google_region               = var.google_region
  local_public_ip             = module.public_ip.public_ip
  kube_cluster_prefix         = var.kube_cluster_prefix
  kube_cluster_version        = var.kube_cluster_version
  kube_nodepool_disk_size     = var.kube_nodepool_disk_size
  kube_nodepool_instance_type = var.kube_nodepool_instance_type
}


module "spinnaker" {
  source  = "app.terraform.io/abitvolatile/spinnaker/helm"
  version = "~> 1.0"

  google_project_name        = local.google_project_name
  helm_chart_version         = var.helm_chart_version
  k8s_access_token           = module.gke.google_service_account_access_token
  k8s_cluster_ca_certificate = module.gke.kubernetes_cluster_ca_certificate
  k8s_cluster_endpoint       = module.gke.kubernetes_cluster_endpoint
  k8s_nodepool_name          = module.gke.kubernetes_nodepool_a_name
}

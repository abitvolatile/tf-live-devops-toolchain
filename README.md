# tf-live-devops-toolchain<br> 
A collection of repositories for deploying what some might call a "Modern DevOps Toolchain" within the Google Cloud Platform using primarily free tools and services such as Github, Terraform Cloud, Packer and Terraform.
<br><br><br>

## Project Overview 

#### Google Cloud Resources:
* Project, Service APIs, Service Accounts and IAM Role Bindings
* VPC-Network, Subnets, Firewall Rules, Load Balancers and Healthchecks
* GCE (Virtual Machine) Instance-Group, Instance Template and Managed Disks
* GKE (Managed Kubernetes) Cluster and NodePool
<br><br><br>


#### Provisioned Services:
* Jenkins [Official Docker Image](https://github.com/jenkinsci/docker)
* Spinnaker [Official Helm Chart](https://hub.helm.sh/charts/stable/spinnaker)
* Prometheus [Custom Monitoring Helm Chart]
  * [Prometheus-Operator](https://hub.helm.sh/charts/stable/prometheus-operator)
    * Prometheus (Prometheus TSDB component)
    * AlertManager (Prometheus alerting component)
    * Kube-State-Metrics (Collects resource state from Kubernetes API and provides data as metrics)
    * Prometheus-Node-Exporter (Collects basic metrics from the underlying OS on nodes)
    * Grafana (Visualization Graphing Tool)
  * [cAdvisor](https://github.com/google/cadvisor) (Collects metrics for container workloads from kubelets)
<br><br><br>


## Technology Overview
Github for Repository and CI Workflows: 
* Each repo has an associated Github Actions Workflow (declarative file)
* The workflow builds the Docker container image containing all tools/dependencies used for performing ANY build or release operations
* All configurations are sourced externally and passed to the container environment runtime allowing for a ubiquitous image to be used across functions & environments
* Build and release pipeline concurrency on the same agent host is possible due to isolation of environment runtime properties (processes, configs, variables, etc..)
* The same image (OS kernel, binaries, file-system, packages) used to deploy dev is the same image used for deploying production
<br>

Packer for Machine Image Templating:
* Builds a CentOS virtual machine image with all OS patches and Docker-CE pre-installed along with any necessary OS configurations (ie. Init Manager) using HashiCorp Packer
<br>

Terraform for Reusable Infrastructure-as-Code Composition and Resource Modules:
* Deploy a uniquely named Google Project (ie. Resource Group) with associated Tags/Labels along with a VPC Network shared within the project
* Deploys a Jenkins Master with plugins pre-installed using  official Docker image running on a Managed Instance Group with Health-checks, Load Balancer, Persistent Storage and restrictive FW rules
* Deploys a Regional Google Kubernetes Cluster with Istio enabled, a Premptible Auto-Scaling Node-Pool (across 3 Zones) with RBAC enabled and a scoped Service Account
* Deploys the Official Spinnaker (Continuous Deployment Tool from Netflix/Google) using a helm chart
* Deploys the Official Prometheus-Operator helm chart along with the cAdvisor (aka. Google's Container Advisor) Exporter resources
<br><br><br>


## Getting Started

### Prerequisites
<br>

**Binaries**
* Install Git binary on local system
* Install Docker Daemon on local system
<br>

**Git Repository**
* Clone this repository locally
* Edit the ./environment/environment.auto.tfvars file (optional)
<br>

**Google Cloud**
* Sign-up for a Google Cloud Platform trial account 
* Create a Google Cloud Organization (Required for use with a GCP Service Account)
* Create a Google Cloud Project for hosting your "Shared" resources
* Create a GCS Bucket to host your Terraform state data
* Create a Service Account and download credentials (JSON format) key file
* Configure the following Billing role (Billing Account User) on the appropriate Billing Account
* Configure the following IAM Bindings (Project Creator, Organization Viewer) at Organization folder level
* Configure the following IAM Bindings (Service Account Token Creator, Owner, Project IAM Admin) on the "Shared" Google Cloud Project
<br>

**Terraform Cloud**
* Create a Terraform Cloud Account (https://app.terraform.io/) to host the TF resource modules
* Create an Organization in Terraform Cloud
* Create a Team API Token in Terraform Cloud
<br><br><br>


### Steps
<br>

#### Build Deployment Container Image
```
docker build -t deployment:latest .
```

#### Start Deployment Container
```
export BUCKET_NAME="<some-bucket-name-here>"
export TF_VAR_google_billing_account='######-######-######'
export TF_VAR_google_org_id='############'
export TF_VAR_google_project_base='tf-gcp-project'
export UID_STRING='123456'
export UID_HASH=$(echo "$UID_STRING" | xxd -r -p | base64 | sed 's/+/-/g; s/\//_/g')

docker run -ti --entrypoint='' \
  -e TERRAFORM_CREDENTIALS="$(cat $HOME/Downloads/.terraformrc)" \
  -e GOOGLE_CLOUD_KEYFILE_JSON="$(cat $HOME/Downloads/gcp-credentials.json)" \
  -e TF_CLI_CONFIG_FILE='/home/alpine/.terraformrc' \
  -e GOOGLE_APPLICATION_CREDENTIALS='/home/alpine/.service_account.json' \
  -e "BUCKET_NAME=$BUCKET_NAME" \
  -e "TF_VAR_google_billing_account=$TF_VAR_google_billing_account" \
  -e "TF_VAR_google_org_id=$TF_VAR_google_org_id" \
  -e "TF_VAR_google_project_base=$TF_VAR_google_project_base" \
  -e "UID_STRING=$UID_STRING" \
  -e "UID_HASH=$UID_HASH" \
  deployment:latest bash
```

#### Start Deployment
```
source /terrform-module/functions.sh
/docker-entrypoint.sh
```
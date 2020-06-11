#!/bin/bash

# Set Static Variables to Pre-Check
VAR_ARRAY=(
  "BUCKET_NAME" 
  "TF_VAR_google_project_base" 
  "UID_STRING")



# Exiting if ANY Error/Failure occurs
set -e


# Creates a Service Account Credential File from Docker Environment Variable
echo "${GOOGLE_CLOUD_KEYFILE_JSON}" > /home/alpine/.service_account.json

# Creates a Terraform Credential File from Docker Environment Variable
echo "${TERRAFORM_CREDENTIALS}" > /home/alpine/.terraformrc


# Packer Build
#echo
#echo "Now Performing Packer Build of Machine Image(s)"
#cd /terraform-module/packer
#hcltool ../examples/example.auto.tfvars | jq -r "{ project_id: .shared_image_project, image_zone: .google_region.single}" > /tmp/vars.json
#packer build -var-file=/tmp/vars.json packer.json


# Load Function Script
cd /terraform-module/
source ./functions.sh 


# Prepare Terraform Composition
cd /terraform-module/examples/
tfenv install



echo 
echo "Starting Variable Pre-Checks..."
var_precheck


echo 
echo "Starting Deployment..."


echo
echo "Now Performing Terraform Init (Initialization of Backend and Provider Plugins)"
tf_init "$BUCKET_NAME" "live/${TF_VAR_google_project_base}-${UID_STRING}"


echo
echo "Now Performing Terraform Validate (Validate/Lint)"
tf_validate
tf_fmt


echo
echo "Printing the Static UID Variables to the Console"
echo "Random UID String: $UID_STRING"
echo "Random UID Hash: $UID_HASH"


# We expect the next few commands to potentially fail if the Project Resource doesn't exist, which fine.
set +e

echo
echo "Importing Resources if they Exist"
terraform state show random_id.project_id || terraform import random_id.project_id $UID_HASH
terraform state show module.project.google_project.project || terraform import module.project.google_project.project "${TF_VAR_google_project_base}-$UID_STRING"

set -e
# Back to Exiting if ANY Error/Failure occurs


echo
echo "Now Performing Terraform Plan (Unit Tests)"
tf_plan


echo
echo "Now Performing Terraform Apply (Provisioning)"
tf_apply


echo
echo "Now Performing Assertions (Integration Tests)"
export TEST_RESULT1=$(terraform output -json | jq -r '.google_project_id.value')
export TEST_RESULT2=$(terraform state pull | jq -r --arg UID_STRING $UID_STRING --arg google_project_base $TF_VAR_google_project_base '.resources[] | select(.instances[].attributes.id == $google_project_base + "-" + $UID_STRING ).instances[].attributes.org_id')
echo "::set-output name=project-id::$TEST_RESULT1"
echo "::set-output name=org-id::$TEST_RESULT2"


#echo
#echo "Now Performing Terraform Destroy (Decommission)"
#tf_destroy


echo
echo
echo 'Workflow has Completed Successfully...'

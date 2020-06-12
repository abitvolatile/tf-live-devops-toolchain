#!/bin/bash

# Function to Check if Variables are Set
variable_check() {
    VAR_INPUT="$1"

    if [ -z "${!VAR_INPUT}" ]
    then
      echo "Variable $VAR_INPUT NOT Set!"
      return 1
    else
      export VAR_VALUE=$(eval 'echo "${'"$VAR_INPUT"'}"')
      echo "Variable ${VAR_INPUT} set to '$VAR_VALUE'"
      return 0
    fi
}



# Pre-Check Loop on Variable Array
var_precheck() {
  for CURR_VAR in "${VAR_ARRAY[@]}"
  do 
    echo "Processing Variable: $CURR_VAR"
    variable_check $CURR_VAR

    if [ $? -ne 0 ]
    then
      exit 1
    fi
  done
}



# Terraform Functions
tf_init() {
    terraform init -backend-config=bucket=$1 -backend-config=prefix=$2
    if [ $? -ne 0 ]
    then
      exit 1
    fi
}


tf_validate() {
    terraform validate -no-color
    if [ $? -ne 0 ]
    then
      exit 1
    fi
}


tf_fmt() {
    terraform fmt --check -recursive -no-color
    if [ $? -ne 0 ]
    then
      exit 1
    fi
}


tf_plan() {
    terraform plan -no-color -out=tfplan.out
    if [ $? -ne 0 ]
    then
      exit 1
    fi
}


tf_apply() {
    terraform apply -auto-approve tfplan.out
    if [ $? -ne 0 ]
    then
      exit 1
    fi
}


tf_destroy() {
    terraform destroy -auto-approve
    if [ $? -ne 0 ]
    then
      exit 1
    fi
}

packer_build() {
    cd $1
    hcltool $2 | jq -r "{ project_id: .shared_image_project, image_zone: .google_region.single}" > /tmp/vars.json
    packer build -var-file=/tmp/vars.json packer.json
    if [ $? -ne 0 ]
    then
      exit 1
    fi
}

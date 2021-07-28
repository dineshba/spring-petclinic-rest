#!/usr/bin/env bash

set -e

if [[ $GOOGLE_APPLICATION_CREDENTIALS_BASE64 ]]; then
    tmpDir=$(mktemp -d -t tmp.XXXXXXXXXX)
    echo "$GOOGLE_APPLICATION_CREDENTIALS_BASE64" | base64 -d >$tmpDir/credentials.json
    export GOOGLE_APPLICATION_CREDENTIALS=$tmpDir/credentials.json
fi

tf_action=$@
if [ $# -eq 0 ]; then
    tf_action=plan
fi

# Due to dead-lock between instance template deletion and update of instance-template-id in instance-group-manager
# during apply, whenever there is an change in google_compute_instance_template,
# we will remove the google_compute_instance_template state from the terraform state
# This will make terraform to create new template without deleting old template
# We can write script to delete the unused instance templates
# Refer existing issue: https://github.com/hashicorp/terraform/issues/6234
if [[ $1 == apply ]]; then
    terraform plan -out=tf-state
    terraform show -json tf-state > tf-state.json
    result=$(cat tf-state.json | jq '.resource_changes[] | select( .type | contains("google_compute_instance_template"))' | jq '. | select(.change.actions[] | contains("create")) | select(.change.actions[] | contains("delete")) | {address: .address, actions: .change.actions}' | jq -r .address)
    if [[ $result ]]; then
        while IFS=" " read -r line;
            do terraform state rm $line;
        done <<< $result
    fi
    terraform $tf_action
else
    terraform $tf_action
fi
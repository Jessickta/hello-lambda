#!/bin/bash

ENV=$1

if [[ $ENV =~ dev|live ]]; then
    echo "Initialising $ENV environment..."
else
    echo "Environment is unknown! Please use dev or live." && exit 1
fi

# Delete any hanging terraform configuration to avoid confusing states
rm -rf .terraform

# Initialise Terraform
terraform init -backend-config=backend-$ENV.config

# Apply Terraform (needs user input)
terraform apply -var env=$ENV
# Simple Hello World Lambda with Terraform #

This repository contains all the code needed to produce an AWS Lambda function that simply says "Hello world :)!" All infrastructure is built through Terraform, and the lambda code is written in NodeJS.

The lambda function in this repository uses a very simple NodeJS handler that responds with a message, which can be accessed via browser.

## Instructions for Use ##

### Account ###

This repo is currently set up to deploy to a particular AWS account. Permissions for the workflow to access this account have been added through OIDC.

### Environments ###

Currently this repo is configured to deploy a dev and a live environment. These are simply examples for the sake of the exercise, and are currently deployed to the same AWS account.

Each environment is configured in GitHub actions, and each have a stand alone lambda/api gateway set up, to show that this codebase can be reused for multiple environments. There are separate config files for each terraform state, and statefiles are saved at different paths, although they are in the same S3 bucket.

### Deploying the Lambda function with GitHub Actions ###

A script (`deploy.sh`) has been written to simplify the deployment process. This script takes one argument, which should be `dev` or `live` depending on which environment should be deployed; if anything other than `dev` or `live` is entered then the script will exit.

The script will initialise terraform and run a `terraform apply` command with the appropriate variables. If there are no changes required, the script will exit successfully, outputting the URL of the lambda function. If there are changes required, you will be prompted to accept or reject the changes. Once you accept these, the infrastructure will be built and you will be able to see the function response message at the outputted URL!

There are two workflows set up for deployment: `dev-deploy` for deploying the dev environment from the `develop` branch, and `live-deploy` for deploying the live environment from the `main` branch. These are triggered by pushes and pull requests to the appropriate branch.

Feature branches can be added at a later stage. In an ideal situation, these would deploy to a dev environment, `develop` would deploy to a staging environment, and `main` would deploy to production (live) - however this has not yet been added.
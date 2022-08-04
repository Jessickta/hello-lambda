### Simple Hello World Lambda with Terraform ###

This repository contains all the code needed to produce an AWS Lambda function that simply says "Hello world :)!" All infrastructure is built through Terraform, and the lambda code is written in NodeJS.

## Instructions for Use ##

The lambda function in this repository uses a very simple NodeJS handler that responds with a message, which can be accessed via browser.

# Account #

This repo is currently set up to deploy to a particular AWS account. To use another account, firstly set your AWS credentials as environment variables:

```
export AWS_ACCESS_KEY_ID=$ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$SECRET_KEY
export AWS_REGION=$REGION
```

You could also change the `profile` name in the config files (`backend-dev.config` and `backend-live.config`, line 5) if you have AWS profiles set up locally.

You will also need to set up two S3 buckets. One for the terraform backend (here it is `lambda-tfstate-files`), and one to hold the packaged lambda code (`hello-lambda-jta` is the example here).

The backend bucket name should be substituted in the config files (line 1), and the lambda bucket in `data.tf` (line 11).

# Environments #

Currently this repo is configured to deploy a dev and a live environment. These are simply examples for the sake of the exercise, and are currently deployed to the same AWS account.

Each environment has a stand alone lambda/api gateway set up, to show that this codebase can be reused for multiple environments. There are separate config files for each terraform state, and statefiles are saved at different paths, although they are in the same S3 bucket.

# Deploying the Lambda function #

A script has been written to simplify the deployment process. This script takes one argument, which should be `dev` or `live` depending on which environment you would like to deploy. If you enter anything other than `dev` or `live` then the script will exit.

To deploy, simply run
```./deploy.sh $ENV```
where `$ENV` is either `dev` or `live`.

The script will initialise terraform and run a `terraform apply` command with the appropriate variables. If there are no changes required, the script will exit successfully, outputting the URL of the lambda function. If there are changed required, you will be prompted to accept or reject the changes. Once you accept these, the infrastructure will be built and you will be able to see the function response message at the outputted URL!
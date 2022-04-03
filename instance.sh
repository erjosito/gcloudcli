#!/bin/local/sh

##########################################
# Basic CLI examples for Google Cloud
#
# Jose Moreno, April 2022
##########################################

# Variables
project_name=instancetest
project_id="${project_name}${RANDOM}"
vm_name=myvm
machine_type=e2-micro
region=europe-north1
zone=europe-north1-c
vpc_name=test
subnet_name=web
subnet_prefix='192.168.1.0/24'

# Get environment info
account=$(gcloud info --format json | jq -r '.config.account')
billing_account=$(gcloud beta billing accounts list --format json | jq -r '.[0].name')
billing_account_short=$(echo "$billing_account" | cut -f 2 -d/)

# Create project
gcloud projects create $project_id --name $project_name
gcloud config set project $project_id
# gcloud services list --available
# gcloud projects update "$project_id" --name $project_name --account "$account" --billing-project
# gcloud beta billing projects describe "$project_id" --format json
gcloud beta billing projects link "$project_id" --billing-account "$billing_account_short"
gcloud services enable compute.googleapis.com

# VPC
gcloud compute networks create $vpc_name --bgp-routing-mode=regional --mtu=1500 --subnet-mode=custom
gcloud compute networks subnets create $subnet_name --network $vpc_name --range $subnet_prefix --region=$region

# Select image
# gcloud compute images list --format json | jq -r '.[] | {id,family,name,status}|join(",")'
# gcloud compute images list --format json | jq -r '.[] | select(.family | contains("ubuntu-2004-lts")) | {id,family,name,status}|join(",")'
# image_id=$(gcloud compute images list --format json | jq -r '.[] | select(.family | contains("ubuntu-2004-lts")) | .id')

# gcloud compute instances create $vm_name "--image=$image_id" --machine-type=MACHINE_TYPE
gcloud compute instances create $vm_name --image-family=ubuntu-2004-lts --machine-type $machine_type \
    --network $vpc_name --subnet $subnet_name

###############
# Diagnostics #
###############

gcloud projects list
gcloud compute networks list
gcloud compute networks subnets list --network $vpc_name
gcloud compute instances describe $vm_name

###########
# Cleanup #
###########

gcloud projects delete "$project_id" --quiet
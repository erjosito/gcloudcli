#!/bin/local/sh

##########################################
# Basic CLI examples for Google Cloud
#
# Jose Moreno, April 2022
##########################################

# Variables
project_name=onpremus
project_id="${project_name}${RANDOM}"
vm_name=myvm
machine_type=e2-micro
region=us-west2
zone=us-west2-b
vpc_name=myvpc
subnet_name=vm
subnet_prefix='192.168.22.0/24'

# Other regions
# region=europe-west3
# zone=europe-west3-b
# region=us-west2
# zone=us-west2-b


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
gcloud compute instances create $vm_name --image-family=ubuntu-2004-lts --image-project=ubuntu-os-cloud --machine-type $machine_type --network $vpc_name --subnet $subnet_name --zone $zone
gcloud compute firewall-rules create allow-icmp --network $vpc_name --priority=1000 --direction=INGRESS --rules=icmp --source-ranges=0.0.0.0/0 --action=ALLOW
gcloud compute firewall-rules create allow-ssh --network $vpc_name --priority=1010 --direction=INGRESS --rules=tcp:22 --source-ranges=0.0.0.0/0 --action=ALLOW
gcloud compute ssh $vm_name --zone=$zone --command="ip a"

# Create interconnect
attachment_name=myattachment
router_name=myrouter
asn=16550
gcloud compute routers create $router_name --project=$project_id --network=$vpc_name --asn=$asn --region=$region
gcloud compute interconnects attachments partner create $attachment_name --region $region --router $router_name --edge-availability-domain availability-domain-1
gcloud compute interconnects attachments describe $attachment_name --region $region

# Next steps: Create VXC in megaport portal

# Activate attachment
gcloud compute interconnects attachments partner update $attachment_name --region $region --admin-enabled


###############
# Diagnostics #
###############

gcloud projects list
gcloud compute networks list
gcloud compute networks subnets list --network $vpc_name
gcloud compute instances describe $vm_name

gcloud compute routers get-status $router_name --region=$region --format=json | jq -r '.result.bestRoutesForRouter[]|{destRange,routeType,nextHopIp} | join("\t")'

###########
# Cleanup #
###########
gcloud project list
gcloud projects delete "$project_id" --quiet
#!/bin/bash

SG_ID="sg-05e225318bf0878b4"
AMI_ID="ami-0220d79f3f480ecf5"

for instance in $@
do
    instance_id=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Reservations[0].Instances[0].privateIpAddress' \
    --output text)

    if [ $instance == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[0].Instances[0].publicIpAddress' \
            --output text
        )
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[0].Instances[0].privateIpAddress' \
            --output text
        )   
    fi     

    echo "IP Adress: $IP"
done

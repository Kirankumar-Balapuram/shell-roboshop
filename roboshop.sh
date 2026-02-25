#!/bin/bash

SG_ID="sg-05e225318bf0878b4"
AMI_ID="ami-0220d79f3f480ecf5"

for instance in $@
do
    INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
        IP=$(
            aws ec2 wait instance-running \
            --instance-ids $INSTANCE_ID  \
            --query 'Reservations[].Instances[].publicIpAddress' \
            --output text
        )
    else
        IP=$(
            aws ec2 wait instance-running \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].privateIpAddress' \
            --output text
        )   
    fi
done   

#!/bin/bash
set -e

SG_ID="sg-05e225318bf0878b4"
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z023399111NZOGHW6MWH3"
DOMAIN_NAME="balapuram.online"
 
for instance in "$@"; do
    echo "Processing instance: $instance"
 
    EXISTING_INSTANCE_ID=$(
        aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$instance" \
                  "Name=instance-state-name,Values=pending,running,stopped,stopping" \
        --query 'Reservations[].Instances[].InstanceId' \
        --output text
    )
 
    if [ -n "$EXISTING_INSTANCE_ID" ]; then
        echo "Instance '$instance' already exists ($EXISTING_INSTANCE_ID). Skipping creation."
        INSTANCE_ID="$EXISTING_INSTANCE_ID"
    else
        echo "Creating instance '$instance'..."
 
        INSTANCE_ID=$(
            aws ec2 run-instances \
            --image-id "$AMI_ID" \
            --instance-type "t3.micro" \
            --security-group-ids "$SG_ID" \
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
            --query 'Instances[0].InstanceId' \
            --output text
        )
    fi
 
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
 
    if [ "$instance" = "frontend" ]; then
        IP=$(
            aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text
        )
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text
        )
    fi
 
    echo "IP Address $instance: $IP"
 
    RECORD_NAME="$instance.$DOMAIN_NAME"
 
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch "{
            \"Comment\": \"Updating record\",
            \"Changes\": [{
                \"Action\": \"UPSERT\",
                \"ResourceRecordSet\": {
                    \"Name\": \"$RECORD_NAME\",
                    \"Type\": \"A\",
                    \"TTL\": 1,
                    \"ResourceRecords\": [{ \"Value\": \"$IP\" }]
                }
            }]
        }"
 
    echo "Record updated for $instance"
done

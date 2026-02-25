#!/bin/bash

SG_ID="sg-05e225318bf0878b4"
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z023399111NZOGHW6MWH3"
DOMAIN_NAME="balapuram.online"

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
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[0].Instances[0].privateIpAddress' \
            --output text
        )   
        RECORD_NAME="$instance.$DOMAIN_NAME" # mongodb.daws88s.online
    fi

    echo "IP Address: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating record",
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
    }
    '

    echo "record updated for $instance"
done

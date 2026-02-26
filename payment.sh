#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.balapuram.online

if [ $USERID -ne 0 ]; then
    echo -e "$R please run this script with root user access"
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
    echo -e "$2 ... $R Failure" | tee -a $LOGS_FILE
    exit 1
else
    echo -e "$2 ... $G Success" | tee -a $LOGS_FILE
fi   
}

dnf install maven -y
VALIDATE $? "Installing Maven"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user already exist ..$Y Skipping"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
cd /app 
unzip /tmp/payment.zip

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing exiting code"

unzip /tmp/payment.zip &>>$LOGS_FILE
VALIDATE $? "unzip payment code"

cd /app
pip3 install -r requirements.txt
VALIDATE $? "installing dependecies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "created systemctl service"

systemctl daemon-reload
systemctl enable payment
systemctl start payment
VALIDATE $? "Enabled and started payment"

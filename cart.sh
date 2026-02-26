#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.balapuram.online

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

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disbaling NodeJS default version"

dnf module enable nodejs:20 -y &>>LOGS_FILE
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Install NodeJS"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user already exist ..$Y Skipping"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip 
VALIDATE $? "Downloading catalog code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing exiting code"

unzip /tmp/cart.zip &>>$LOGS_FILE
VALIDATE $? "unzip cart code"

npm install &>>$LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "created systemctl service"

systemctl daemon-reload
systemctl enable cart &>>$LOGS_FILE
systemctl start cart
VALIDATE $? "starting and enabling cart"

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

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
cd /app 
unzip /tmp/shipping.zip

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing exiting code"

unzip /tmp/shipping.zip &>>$LOGS_FILE
VALIDATE $? "unzip shipping code"

cd /app 
mvn clean package 
VALIDATE $? "Installing and Building shipping"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Moving and Renaming shipping"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "created systemctl service"

dnf install mysql -y
VALIDATE $? "installing Mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql

systemctl enable shipping
systemctl start shipping
VALIDATE $? "Enabled and started shipping"

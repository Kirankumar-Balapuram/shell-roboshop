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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Added RabbitMQ repo"

dnf install rabbitmq-server -y
VALIDATE $? "Installing RabbbitMQ server"

systemctl enable rabbitmq-server
systemctl start rabbitmq-server
VALIDATE $? "Enabled and started rabbitmq"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "created user and given permissions"

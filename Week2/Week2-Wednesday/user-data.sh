#!/bin/bash

yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Provisioned automatically by user-data - Week 2 Day 3</h1>" > /var/www/html/index.html

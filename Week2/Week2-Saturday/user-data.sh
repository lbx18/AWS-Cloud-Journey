#!/bin/bash
yum update -y
yum upgrade -y 
yum install -y httpd
systemctl start httpd 
systemctl enable httpd

echo "<h1>Rebuilt from scratch - Week 2 Saturday</h1> " > /var/www/html/index.html

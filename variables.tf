# AWS Region
variable "region" {
  description = "The AWS region to deploy resources"
  default     = "us-east-1"
}

# VPC ID
variable "vpc_id" {
  description = "The VPC ID where the resources will be deployed"
}

# Subnet IDs
variable "subnet_ids" {
  description = "List of subnet IDs where the Auto Scaling group will launch instances"
  type        = list(string)
}

# Instance Type
variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

# AMI ID
variable "ami_id" {
  description = "The Amazon Machine Image (AMI) ID to use for EC2 instances"
  default     = "ami-0a5c3558529277641"  # Amazon Linux 2 AMI for us-east-1
}

# SSL Certificate ARN from ACM
variable "certificate_arn" {
  description = "The ARN of the SSL certificate from AWS Certificate Manager (ACM)"
}

# Minimum, maximum, and desired instance counts
variable "min_size" {
  description = "Minimum number of EC2 instances in the Auto Scaling group"
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the Auto Scaling group"
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in the Auto Scaling group"
  default     = 2
}

# Welcome message for the web server
variable "welcome_message" {
  description = "The welcome message to display on the Apache web page"
  default     = "This project is deploying 2 Apache WebServers on AWS Auto Scaling Group!"
}

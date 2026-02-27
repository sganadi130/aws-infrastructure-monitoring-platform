variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ec2_scheduler_zip" {
  description = "Path to EC2 scheduler Lambda zip file"
  type        = string
}

variable "ebs_cleanup_zip" {
  description = "Path to EBS cleanup Lambda zip file"
  type        = string
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region, default: sydney"
}

variable "aws_id" {
  type        = string
  description = "AWS Access Key ID"
}
variable "aws_secret" {
  type        = string
  description = "AWS Secret Access Key"
}

variable "amis" {
  type = map(any)
  default = {
    ap-southeast-2 = "ami-076a5bf4a712000ed"
    us-east-1      = "ami-013f17f36f8b1fefb"
  }
  description = "AMI ID, default: Ubuntu18.04 x86_64"
}

variable "staging_name" {
  type        = string
  description = "EC2 instance name for application staging"
}

variable "staging_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type for application staging"
}

variable "backend_name" {
  type        = string
  description = "EC2 instance name for application backend"
}

variable "backend_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type for application backend"
}

variable "backup_name" {
  type        = string
  description = "EC2 instance name for application backend"
}

variable "backup_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type for application backend"
}

variable "scheduler_name" {
  type        = string
  description = "EC2 instance name for application scheduler"
}

variable "scheduler_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type for application scheduler"
}

variable "additional_eip_count" {
  type        = number
  default     = 0
  description = "EC2 instance additional eip number for each server, default: 0"
}

variable "ebs_count" {
  type        = number
  default     = 0
  description = "EC2 instance ebs number for each server, default: 0"
}

variable "ebs_size" {
  type        = number
  default     = 10
  description = "EC2 instance ebs volume size as GB, default: 10"
}

variable "scheduler_volume" {
  type        = number
  default     = 20
  description = "EC2 instance root volume size as GB, default: 20"
}

variable "staging_volume" {
  type        = number
  default     = 20
  description = "EC2 instance root volume size as GB, default: 20"
}

variable "backend_volume" {
  type        = number
  default     = 20
  description = "EC2 instance root volume size as GB, default: 20"
}

variable "backup_volume" {
  type        = number
  default     = 20
  description = "EC2 instance root volume size as GB, default: 20"
}

variable "ssh_key_name" {
  type        = string
  default     = "work"
  description = "SSH key name"
}

variable "public_key_path" {
  type        = string
  default     = "keypairs"
  description = "SSH public key path"
}

variable "public_key_file" {
  type        = string
  default     = "work.pub"
  description = "SSH public key file"
}

variable "environment" {
  type        = string
  description = "Application runtime environment"
}

variable "application" {
  type        = string
  description = "application name"
}

variable "organization" {
  type        = string
  description = "organization name"
}

variable "s3_enabled" {
  type        = bool
  default     = false
  description = "s3 "
}

variable "rds_enabled" {
  type        = bool
  default     = false
  description = "rds service switch"
}

variable "elasticache_enabled" {
  type        = bool
  default     = false
  description = "elasticache service switch"
}

variable "acm_enabled" {
  type        = bool
  default     = false
  description = "acm service switch"
}

variable "dns_enabled" {
  type        = bool
  default     = false
  description = "switch for route53 service"
}

variable "terraform_debug" {
  type        = bool
  default     = false
  description = "terraform script debug switch"
}

variable "application_domain" {
  type        = string
  description = "Domain name for current application"
}

variable "database_passwd" {
  type        = string
  default     = "postgres"
  description = "password for RDS database"
}

variable "backup_retention" {
  type        = number
  default     = 0
  description = "RDS backup retension period"
}

variable "elb_log_enabled" {
  type        = bool
  default     = true
  description = "loadbalancer log switch, stored in S3"
}

variable "autoscale_name" {
  type        = string
  default     = "asg"
  description = "autoscale group name"
}

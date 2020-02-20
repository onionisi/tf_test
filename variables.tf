variable "region" {
  type        = string
  default     = "ap-southeast-2"
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
  type = map
  default = {
    ap-southeast-2 = "ami-02a599eb01e3b3c5b"
  }
  description = "AMI ID, default: Ubuntu18.04 x86_64"
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

variable "scheduler_name" {
  type        = string
  description = "EC2 instance name for application scheduler"
}

variable "scheduler_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type for application scheduler"
}

variable "eip_count" {
  type        = number
  default     = 1
  description = "EC2 instance eip number for each server, default: 1"
}

variable "ebs_count" {
  type        = number
  default     = 1
  description = "EC2 instance ebs number for each server, default: 1"
}

variable "ebs_size" {
  type        = number
  default     = 10
  description = "EC2 instance ebs size as GB, default: 10"
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

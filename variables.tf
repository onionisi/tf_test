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

variable "backend_count" {
  type        = number
  default     = 1
  description = "EC2 instance number for application backend, default: 1"
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

variable "scheduler_count" {
  type        = number
  default     = 1
  description = "EC2 instance number for application scheduler, default: 1"
}

variable "ssh_key_name" {
  type        = string
  default     = "work"
  description = "SSH key name"
}

variable "ssh_public_key" {
  type        = string
  default     = "keypairs/ssh.pub"
  description = "SSH public key"
}

variable "enviroment" {
  type        = string
  description = "Application runtime enviroment"
}

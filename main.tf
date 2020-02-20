provider "aws" {
  region = var.region
  # using credential from aws configure profile
  # profile = "fitstop"
  # static credential
  access_key = var.aws_id
  secret_key = var.aws_secret
}


/*******************************************************************************
Network Configuration
*******************************************************************************/
# TODO: customized VPC and subnet
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

# TODO: ingress cidr block
module "ssh_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/ssh"

  name        = "ssh"
  description = "Security group for web-server with HTTP ports open within VPC"

  vpc_id              = data.aws_vpc.default.id
  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "http_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "http"
  description = "Security group for ssh-server with SSH ports open within VPC"

  vpc_id              = data.aws_vpc.default.id
  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/https-443"

  name        = "https"
  description = "Security group for web-server with HTTPS ports open within VPC"

  vpc_id              = data.aws_vpc.default.id
  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "postgresql_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/postgresql"

  name        = "postgresql"
  description = "Security group for database with Postgresql ports open within VPC"

  vpc_id              = data.aws_vpc.default.id
  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "redis-sg" {
  source = "terraform-aws-modules/security-group/aws//modules/redis"

  name        = "redis"
  description = "Security group for cache service with redis ports open within VPC"

  vpc_id              = data.aws_vpc.default.id
  ingress_cidr_blocks = ["0.0.0.0/0"]
}

# TODO: elastic IP
# resource "aws_eip" "production" {
#   count = var.backend_count + var.scheduler_count
#   vpc = true
# }


/*******************************************************************************
LoadBalancer: ELB
*******************************************************************************/


/*******************************************************************************
Application Server
*******************************************************************************/
resource "aws_key_pair" "ssh" {
  key_name   = var.ssh_key_name
  public_key = file(var.ssh_public_key)
}

module "fitstop_backend" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = var.backend_name
  instance_count = var.backend_count
  instance_type  = var.backend_type
  key_name       = aws_key_pair.ssh.key_name
  ami            = lookup(var.amis, var.region)

  # network related
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.ssh_sg.this_security_group_id, module.http_sg.this_security_group_id]
  subnet_id                   = tolist(data.aws_subnet_ids.all.ids)[0]

  # TODO:customized script
  # user_data = var.bootstrap_script
  tags = {
    Name        = var.backend_name
    Environment = var.enviroment
  }
}

module "fitstop_scheduler" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = var.scheduler_name
  instance_count = var.scheduler_count
  instance_type  = var.scheduler_type
  key_name       = aws_key_pair.ssh.key_name
  ami            = lookup(var.amis, var.region)

  # network related
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.ssh_sg.this_security_group_id]
  subnet_id                   = tolist(data.aws_subnet_ids.all.ids)[0]

  # TODO:customized script
  # user_data = var.bootstrap_script
  tags = {
    Name        = var.scheduler_name
    Environment = var.enviroment
  }
}

/*******************************************************************************
Storage: S3
*******************************************************************************/

/*******************************************************************************
Cache: ElastiCache
*******************************************************************************/

/*******************************************************************************
Database: RDS
*******************************************************************************/

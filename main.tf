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
TODO: customized VPC and subnet
*******************************************************************************/
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_security_groups" "default" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
}

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
  source  = "cloudposse/ec2-instance/aws"
  version = "0.14.0"

  namespace     = var.organization
  name          = var.backend_name
  instance_type = var.backend_type
  ssh_key_pair  = aws_key_pair.ssh.key_name
  ami           = lookup(var.amis, var.region)
  ami_owner     = "099720109477"
  environment   = var.project
  stage         = var.environment

  # network related
  allowed_ports               = [22, 80, 443]
  associate_public_ip_address = true
  additional_ips_count        = var.eip_count
  security_groups             = data.aws_security_groups.default.ids
  subnet                      = tolist(data.aws_subnet_ids.all.ids)[0]
  vpc_id                      = data.aws_vpc.default.id

  # block storage
  ebs_volume_count = var.ebs_count
  ebs_volume_size  = var.ebs_size

  # TODO:customized script
  # user_data = var.bootstrap_script
}

module "fitstop_scheduler" {
  source  = "cloudposse/ec2-instance/aws"
  version = "0.14.0"

  namespace     = var.organization
  name          = var.scheduler_name
  instance_type = var.scheduler_type
  ssh_key_pair  = aws_key_pair.ssh.key_name
  ami           = lookup(var.amis, var.region)
  ami_owner     = "099720109477"
  environment   = var.project
  stage         = var.environment

  # network related
  allowed_ports               = [22]
  associate_public_ip_address = true
  additional_ips_count        = var.eip_count
  security_groups             = data.aws_security_groups.default.ids
  subnet                      = tolist(data.aws_subnet_ids.all.ids)[0]
  vpc_id                      = data.aws_vpc.default.id

  # block storage
  ebs_volume_count = var.ebs_count
  ebs_volume_size  = var.ebs_size

  # TODO:customized script
  # user_data = var.bootstrap_script
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

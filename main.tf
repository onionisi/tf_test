provider "aws" {
  region = var.region
  // using credential from aws configure profile
  # profile = var.application
  // static credential
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

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_subnet" "single" {
  for_each = data.aws_subnet_ids.all.ids
  id       = each.value
}

data "aws_security_groups" "default" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
}

# data "aws_route53_zone" "domain" {
#   name = "${var.application_domain}."
# }

data "aws_acm_certificate" "certificate" {
  domain   = "*.${var.application_domain}"
  statuses = ["ISSUED"]
}

/*******************************************************************************
certificate: ACM
*******************************************************************************/
module "app_certificate" {
  source  = "cloudposse/acm-request-certificate/aws"
  version = "0.13.1"

  enabled = var.acm_enabled

  domain_name                       = var.application_domain
  validation_method                 = "DNS"
  ttl                               = 300
  subject_alternative_names         = ["*.${var.application_domain}"]
  process_domain_validation_options = true
  wait_for_certificate_issued       = false
}


/*******************************************************************************
LoadBalancer: ELB
*******************************************************************************/
module "app_alb" {
  source  = "cloudposse/alb/aws"
  version = "0.32.1"


  name            = var.application
  internal        = false
  ip_address_type = "ipv4"

  deletion_protection_enabled       = var.terraform_debug ? false : true
  cross_zone_load_balancing_enabled = true

  security_group_ids = data.aws_security_groups.default.ids
  subnet_ids         = data.aws_subnet_ids.all.ids
  vpc_id             = data.aws_vpc.default.id

  // http/https
  http2_enabled   = true
  http_redirect   = true
  https_enabled   = true
  certificate_arn = data.aws_acm_certificate.certificate.arn

  // target
  target_group_name        = "app-upstream"
  target_group_port        = 80
  target_group_target_type = "instance"

  // health check

  // access log
  access_logs_enabled                     = var.elb_log_enabled
  access_logs_prefix                      = "${var.application}_access_logs"
  alb_access_logs_s3_bucket_force_destroy = var.terraform_debug ? true : false
}

# register target
# resource "aws_lb_target_group_attachment" "http" {
#   target_group_arn = module.app_alb.default_target_group_arn
#   target_id        = module.app_backend.id
#   port             = 80
# }

# resource "aws_lb_target_group_attachment" "backup" {
#   target_group_arn = module.app_alb.default_target_group_arn
#   target_id        = module.app_backup.id
#   port             = 80
# }

/*******************************************************************************
DNS: Route53
*******************************************************************************/
# module "app_api" {
#   source  = "cloudposse/route53-alias/aws"
#   version = "0.5.0"

#   enabled        = var.dns_enabled
#   aliases        = ["api.${var.application_domain}"]
#   parent_zone_id = data.aws_route53_zone.domain.zone_id

#   target_dns_name = module.app_alb.alb_dns_name
#   target_zone_id  = module.app_alb.alb_zone_id
# }

# module "app_admin" {
#   source  = "cloudposse/route53-alias/aws"
#   version = "0.5.0"

#   enabled        = var.dns_enabled
#   aliases        = ["admin.${var.application_domain}"]
#   parent_zone_id = data.aws_route53_zone.domain.zone_id

#   target_dns_name = module.app_alb.alb_dns_name
#   target_zone_id  = module.app_alb.alb_zone_id
# }

/*******************************************************************************
Application Server
*******************************************************************************/
module "key_pair" {
  source  = "cloudposse/key-pair/aws"
  version = "0.18.0"

  enabled = true

  namespace = var.application
  stage     = var.environment
  name      = var.ssh_key_name

  ssh_public_key_path = var.public_key_path
  ssh_public_key_file = var.public_key_file
  generate_ssh_key    = false
}


module "app_asg" {
  source  = "cloudposse/ec2-autoscale-group/aws"
  version = "0.23.0"

  enabled      = true
  force_delete = var.terraform_debug ? true : false

  namespace = var.application
  stage     = var.environment
  name      = var.autoscale_name

  image_id                    = lookup(var.amis, var.region)
  key_name                    = module.key_pair.key_name
  associate_public_ip_address = true
  instance_type               = "t3.medium"
  security_group_ids          = data.aws_security_groups.default.ids
  subnet_ids                  = data.aws_subnet_ids.all.ids
  target_group_arns           = [module.app_alb.default_target_group_arn]
  # user_data_base64 = "${base64encode(local.userdata)}"
  block_device_mappings = [
    {
      device_name  = "/dev/sda1"
      no_device    = "false"
      virtual_name = "root"
      ebs = {
        encrypted             = true
        volume_size           = 40
        delete_on_termination = true
        iops                  = null
        kms_key_id            = null
        snapshot_id           = null
        volume_type           = "standard"
      }
    }
  ]

  health_check_type         = "EC2"
  min_size                  = 2
  max_size                  = 4
  wait_for_capacity_timeout = "2m"
  termination_policies      = ["NewestInstance"]

  tags = {
    Name = var.autoscale_name
  }

  # Auto-scaling policies and CloudWatch metric alarms
  autoscaling_policies_enabled            = true
  cpu_utilization_high_threshold_percent  = "50"
  cpu_utilization_high_evaluation_periods = 2
  cpu_utilization_high_period_seconds     = 60
  cpu_utilization_low_threshold_percent   = "20"
  cpu_utilization_low_evaluation_periods  = 2
  cpu_utilization_low_period_seconds      = 300
}


# module "app_staging" {
#   source  = "cloudposse/ec2-instance/aws"
#   version = "0.14.0"

#   namespace     = var.application
#   stage         = var.environment
#   name          = var.staging_name
#   instance_type = var.staging_type
#   ami           = lookup(var.amis, var.region)
#   ami_owner     = "099720109477"
#   ssh_key_pair  = module.key_pair.key_name

#   // volume
#   delete_on_termination = true
#   root_volume_size      = var.staging_volume
#   ebs_volume_count      = var.ebs_count
#   ebs_volume_size       = var.ebs_size

#   // network related
#   allowed_ports      = [22, 80, 443]
#   assign_eip_address = true
#   # associate_public_ip_address = true
#   # additional_ips_count        = var.eip_count
#   security_groups = data.aws_security_groups.default.ids
#   subnet          = tolist(data.aws_subnet_ids.all.ids)[0]
#   vpc_id          = data.aws_vpc.default.id

#   // TODO:customized script
#   # user_data = var.bootstrap_script

#   // alarm
#   // details monitoring with status check at no charge
#   monitoring           = true
#   metric_namespace     = "AWS/EC2"
#   metric_name          = "StatusCheckFailed_Instance"
#   comparison_operator  = "GreaterThanOrEqualToThreshold"
#   metric_threshold     = 1
#   statistic_level      = "Maximum" // SampleCount, Average, Sum, Minimum, Maximum
#   default_alarm_action = "action/actions/AWS_EC2.InstanceId.Reboot/1.0"

#   tags = {
#     Name = var.staging_name
#   }
# }


# module "app_backend" {
#   source  = "cloudposse/ec2-instance/aws"
#   version = "0.14.0"

#   namespace     = var.application
#   stage         = var.environment
#   name          = var.backend_name
#   instance_type = var.backend_type
#   ami           = lookup(var.amis, var.region)
#   ami_owner     = "099720109477"
#   ssh_key_pair  = module.key_pair.key_name

#   // volume
#   delete_on_termination = true
#   root_volume_size      = var.backend_volume
#   ebs_volume_count      = var.ebs_count
#   ebs_volume_size       = var.ebs_size

#   // network related
#   allowed_ports      = [22, 80]
#   assign_eip_address = true
#   # associate_public_ip_address = true
#   # additional_ips_count        = var.eip_count
#   security_groups = data.aws_security_groups.default.ids
#   subnet          = tolist(data.aws_subnet_ids.all.ids)[0]
#   vpc_id          = data.aws_vpc.default.id

#   // TODO:customized script
#   # user_data = var.bootstrap_script

#   // alarm
#   // details monitoring with status check at no charge
#   monitoring           = true
#   metric_namespace     = "AWS/EC2"
#   metric_name          = "StatusCheckFailed_Instance"
#   comparison_operator  = "GreaterThanOrEqualToThreshold"
#   metric_threshold     = 1
#   statistic_level      = "Maximum" // SampleCount, Average, Sum, Minimum, Maximum
#   default_alarm_action = "action/actions/AWS_EC2.InstanceId.Reboot/1.0"

#   tags = {
#     Name = var.backend_name
#   }
# }


# module "app_backup" {
#   source  = "cloudposse/ec2-instance/aws"
#   version = "0.14.0"

#   namespace     = var.application
#   stage         = var.environment
#   name          = var.backup_name
#   instance_type = var.backup_type
#   ami           = lookup(var.amis, var.region)
#   ami_owner     = "099720109477"
#   ssh_key_pair  = module.key_pair.key_name

#   // volume
#   delete_on_termination = true
#   root_volume_size      = var.backup_volume
#   ebs_volume_count      = var.ebs_count
#   ebs_volume_size       = var.ebs_size

#   // network related
#   allowed_ports      = [22, 80]
#   assign_eip_address = true
#   # associate_public_ip_address = true
#   # additional_ips_count        = var.eip_count
#   security_groups = data.aws_security_groups.default.ids
#   subnet          = tolist(data.aws_subnet_ids.all.ids)[1]
#   vpc_id          = data.aws_vpc.default.id

#   // TODO:customized script
#   # user_data = var.bootstrap_script

#   // alarm
#   // details monitoring with status check at no charge
#   monitoring           = true
#   metric_namespace     = "AWS/EC2"
#   metric_name          = "StatusCheckFailed_Instance"
#   comparison_operator  = "GreaterThanOrEqualToThreshold"
#   metric_threshold     = 1
#   statistic_level      = "Maximum" // SampleCount, Average, Sum, Minimum, Maximum
#   default_alarm_action = "action/actions/AWS_EC2.InstanceId.Reboot/1.0"

#   tags = {
#     Name = var.backup_name
#   }
# }

# module "app_scheduler" {
#   source  = "cloudposse/ec2-instance/aws"
#   version = "0.14.0"

#   namespace     = var.application
#   stage         = var.environment
#   name          = var.scheduler_name
#   instance_type = var.scheduler_type
#   ami           = lookup(var.amis, var.region)
#   ami_owner     = "099720109477"
#   ssh_key_pair  = module.key_pair.key_name

#   // volume
#   delete_on_termination = true
#   root_volume_size      = var.scheduler_volume
#   ebs_volume_count      = var.ebs_count
#   ebs_volume_size       = var.ebs_size

#   # network related
#   allowed_ports      = [22]
#   assign_eip_address = true
#   # associate_public_ip_address = true
#   # additional_ips_count        = var.eip_count
#   security_groups = data.aws_security_groups.default.ids
#   subnet          = tolist(data.aws_subnet_ids.all.ids)[0]
#   vpc_id          = data.aws_vpc.default.id

#   // TODO:customized script
#   # user_data = var.bootstrap_script

#   // alarm 
#   // details monitoring with status check at no charge
#   monitoring           = true
#   metric_namespace     = "AWS/EC2"
#   metric_name          = "StatusCheckFailed_Instance"
#   comparison_operator  = "GreaterThanOrEqualToThreshold"
#   metric_threshold     = 1
#   statistic_level      = "Maximum" // SampleCount, Average, Sum, Minimum, Maximum
#   default_alarm_action = "action/actions/AWS_EC2.InstanceId.Reboot/1.0"

#   tags = {
#     Name = var.scheduler_name
#   }
# }

/*******************************************************************************
Storage: S3
*******************************************************************************/
module "app_storage" {
  source  = "cloudposse/s3-bucket/aws"
  version = "0.35.0"

  enabled = var.s3_enabled

  name      = "s3bucket"
  namespace = var.application
  stage     = var.environment

  // public-read-write ,default: private
  acl                = "public-read"
  versioning_enabled = false

  // specific user for S3 and policy
  user_enabled           = true
  allowed_bucket_actions = ["s3:GetObject", "s3:ListBucket", "s3:PutObject", "s3:PutObjectAcl", "s3:DeleteObject"]

  // public permission bucket policy 
  # policy = jsonencode(
  #   {
  #     Statement = [
  #       {
  #         Sid = "AllowPublicReadWrite"
  #         Action = [
  #           "s3:ListBucket",
  #           "s3:GetObject",
  #           "s3:PutObject",
  #           "s3:DeleteObject",
  #         ]
  #         Effect = "Allow"
  #         Principal = {
  #           AWS = ["*"]
  #         }
  #         Resource = [
  #           "arn:aws:s3:::${var.application}-${var.environment}-s3bucket/*",
  #         ]
  #       }
  #     ]
  #     Version = "2012-10-17"
  #   }
  # )


  # lifecycle_rules = [
  #   {
  #     "abort_incomplete_multipart_upload_days": 90,
  #     "deeparchive_transition_days": 90,
  #     "enable_current_object_expiration": true,
  #     "enable_deeparchive_transition": false,
  #     "enable_glacier_transition": true,
  #     "enable_standard_ia_transition": false,
  #     "enabled": false,
  #     "expiration_days": 90,
  #     "glacier_transition_days": 60,
  #     "noncurrent_version_deeparchive_transition_days": 60,
  #     "noncurrent_version_expiration_days": 90,
  #     "noncurrent_version_glacier_transition_days": 30,
  #     "prefix": "",
  #     "standard_transition_days": 30,
  #     "tags": {}
  #   }
  # ]

  force_destroy = var.terraform_debug ? true : false

  tags = {
    Name = "s3bucket"
  }
}


/*******************************************************************************
Cache: ElastiCache
*******************************************************************************/
module "app_cache" {
  source  = "cloudposse/elasticache-redis/aws"
  version = "0.37.0"

  enabled = var.elasticache_enabled

  name                    = "redis"
  allowed_security_groups = data.aws_security_groups.default.ids
  subnets                 = data.aws_subnet_ids.all.ids
  vpc_id                  = data.aws_vpc.default.id
  allowed_cidr_blocks     = [for s in data.aws_subnet.single : s.cidr_block]
  availability_zones      = data.aws_availability_zones.available.names

  family         = "redis5.0"
  engine_version = "5.0.6"
  instance_type  = "cache.t2.medium"

  at_rest_encryption_enabled = false
  transit_encryption_enabled = false
  # auth_token = "" // must be longer than 16 chars

  # cluster
  cluster_size                         = 2 // ignored when cluster mode enabled
  multi_az_enabled                     = true
  automatic_failover_enabled           = true  // not available for T1/T2
  cluster_mode_enabled                 = false // failover must be enabled
  cluster_mode_num_node_groups         = 0
  cluster_mode_replicas_per_node_group = 0

  // snapshot
  snapshot_retention_limit = 0
  snapshot_window          = "22:00-03:00"

  // alarm
  # ok_actions                   = [""]
  # alarm_actions                = [""]
  alarm_cpu_threshold_percent  = 75
  alarm_memory_threshold_bytes = 10000000

  parameter = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    },
    {
      name  = "reserved-memory-percent"
      value = 25 // default: 25
    }
  ]

  tags = {
    Name = "${var.application}_cache"
  }
}


/*******************************************************************************
Database: RDS
*******************************************************************************/
module "app_database" {
  source  = "cloudposse/rds/aws"
  version = "0.35.1"

  enabled = var.rds_enabled

  namespace = var.application
  stage     = var.environment

  name               = "database"
  security_group_ids = data.aws_security_groups.default.ids
  subnet_ids         = data.aws_subnet_ids.all.ids
  vpc_id             = data.aws_vpc.default.id
  // Route53 record for RDS
  # host_name          = "database"
  # dns_zone_id     = data.aws_route53_zone.domain.zone_id

  engine               = "postgres"
  engine_version       = "11.5"
  major_engine_version = "11"
  instance_class       = "db.t2.small"
  database_user        = var.application
  database_password    = var.database_passwd
  database_port        = 5432
  database_name        = var.application
  db_parameter_group   = "postgres11"
  db_parameter         = []

  publicly_accessible = false
  allowed_cidr_blocks = [for s in data.aws_subnet.single : s.cidr_block]

  storage_type          = "gp2"
  allocated_storage     = 30
  max_allocated_storage = 1000
  storage_encrypted     = false
  multi_az              = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  // maintenance
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = false
  maintenance_window          = "Mon:03:00-Mon:04:00"

  // cluster will be created from specified ID 
  # snapshot_identifier         = "rds:production-2015-06-26-06-05"
  skip_final_snapshot   = false
  copy_tags_to_snapshot = true
  // >0 enable backups
  backup_retention_period = var.backup_retention
  backup_window           = "22:00-03:00"

  deletion_protection = var.terraform_debug ? false : true

  tags = {
    Name = "${var.application}_database"
  }
}

/*******************************************************************************
* common variable
*******************************************************************************/
organization = "organization"
application  = "test"
region       = "ap-southeast-2"

# aws account
aws_id     = "FAKE_ID"
aws_secret = "FAKE_SEC"

# environment
environment     = "production"
terraform_debug = true

/*******************************************************************************
Network configure: VPC
*******************************************************************************/
application_domain = "test.com"


/*******************************************************************************
certificate: ACM
*******************************************************************************/
acm_enabled = false

/*******************************************************************************
LoadBalancer: ELB
*******************************************************************************/
elb_log_enabled = true


/*******************************************************************************
DNS: Route53
*******************************************************************************/
dns_enabled = false


/*******************************************************************************
Application Server: EC2
*******************************************************************************/
# AutoScaling attribute
autoscale_name = "asg"

# EC2 staging attribute
staging_name   = "staging"
staging_type   = "t3.small"
staging_volume = 30

# EC2 backend attribute
backend_name   = "puma"
backend_type   = "t3.medium"
backend_volume = 50

# EC2 backup attribute
backup_name   = "backup"
backup_type   = "t3.medium"
backup_volume = 50

# EC2 scheduler attribute
scheduler_name   = "sidekiq"
scheduler_type   = "t3.medium"
scheduler_volume = 20

/*******************************************************************************
Storage: S3
*******************************************************************************/
s3_enabled = true

/*******************************************************************************
Cache: ElastiCache
*******************************************************************************/
elasticache_enabled = true

/*******************************************************************************
Database: RDS
*******************************************************************************/
rds_enabled      = true
database_passwd  = "G=TzazGx96%abAmJ"
backup_retention = 7 # auto-backup [0-35]

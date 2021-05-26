# output "staging_server" {
#   value       = module.app_staging.public_ip
#   description = "staging server ip address"
# }

# output "app_server" {
#   value       = module.app_backend.public_ip
#   description = "backend server ip address"
# }

# output "backup_server" {
#   value       = module.app_backup.public_ip
#   description = "backup server ip address"
# }

# output "sidekiq_server" {
#   value       = module.app_scheduler.public_ip
#   description = "sidekiq server ip address"
# }

output "database_endpoint" {
  value       = module.app_database.instance_endpoint
  description = "Postgres instance endpoint"
}

output "cache_endpoint" {
  value       = module.app_cache.endpoint
  description = "Redis primary endpoint"
}

output "s3bucket_arn" {
  value       = module.app_storage.bucket_arn
  description = "S3 bucket arn"
}

// if S3 user anebled
output "s3bucket_user" {
  value       = module.app_storage.user_name
  description = "S3 bucket user name"
}

output "s3bucket_user_key" {
  value       = module.app_storage.access_key_id
  sensitive   = true
  description = "S3 bucket user access key id"
}

output "s3bucket_user_secret" {
  value       = module.app_storage.secret_access_key
  sensitive   = true
  description = "S3 bucket user secret access key"
}

# output "alb_dns_name" {
#   value       = module.app_alb.alb_dns_name
#   description = "ALB DNS name"
# }

# output "alb_zone_id" {
#   value       = module.app_alb.alb_zone_id
#   description = "ALB zone id"
# }

output "app_asg_name" {
  value       = module.app_asg.autoscaling_group_name
  description = "The AutoScaling Group name"
}

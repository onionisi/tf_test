output "fitstop_server" {
  value       = module.fitstop_backend.public_ip
  description = "backend server ip address"
}

output "sidekiq_server" {
  value       = module.fitstop_scheduler.public_ip
  description = "sidekiq server ip address"
}

output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = aws_instance.bastion.public_ip
}

output "app_instance_ids" {
  description = "IDs of app instances"
  value       = aws_instance.app[*].id
}

output "app_private_ips" {
  description = "Private IPs of app instances"
  value       = aws_instance.app[*].private_ip
}

output "monitoring_public_ip" {
  description = "Public IP of monitoring instance"
  value       = aws_instance.monitoring.public_ip
}

output "monitoring_private_ip" {
  description = "Private IP of monitoring instance"
  value       = aws_instance.monitoring.private_ip
}

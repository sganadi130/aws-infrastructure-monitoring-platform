output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = module.compute.bastion_public_ip
}

output "app_instance_ids" {
  description = "IDs of app instances for Lambda"
  value       = module.compute.app_instance_ids
}

output "monitoring_public_ip" {
  description = "Public IP of monitoring instance"
  value       = module.compute.monitoring_public_ip
}

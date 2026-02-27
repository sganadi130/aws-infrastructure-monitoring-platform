output "ec2_scheduler_arn" {
  description = "ARN of EC2 scheduler Lambda"
  value       = aws_lambda_function.ec2_scheduler.arn
}

output "ebs_cleanup_arn" {
  description = "ARN of EBS cleanup Lambda"
  value       = aws_lambda_function.ebs_cleanup.arn
}

output "lambda_role_arn" {
  description = "ARN of Lambda IAM role"
  value       = aws_iam_role.lambda_scheduler.arn
}

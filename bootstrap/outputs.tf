output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "Name of the S3 bucket for Terraform state"
}

output "config_secret_name" {
  value       = aws_secretsmanager_secret.tf_config.name
  description = "Name of the Secrets Manager secret holding custom Terraform config"
}

output "config_secret_arn" {
  value       = aws_secretsmanager_secret.tf_config.arn
  description = "ARN of the Secrets Manager secret holding custom Terraform config"
}

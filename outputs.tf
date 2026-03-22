##############################
# Networking Outputs
##############################

output "primary_vpc_id" {
  description = "ID of the primary VPC in us-east-1"
  value       = aws_vpc.primary_vpc.id
}

output "primary_subnet_id" {
  description = "ID of the primary subnet in us-east-1"
  value       = aws_subnet.primary_subnet.id
}

output "primary_security_group_id" {
  description = "ID of the primary security group in us-east-1"
  value       = aws_security_group.app_sg.id
}

output "secondary_vpc_id" {
  description = "ID of the secondary VPC in us-west-2"
  value       = aws_vpc.secondary_vpc.id
}

output "secondary_subnet_id" {
  description = "ID of the secondary subnet in us-west-2"
  value       = aws_subnet.secondary_subnet.id
}

output "secondary_security_group_id" {
  description = "ID of the secondary security group in us-west-2"
  value       = aws_security_group.secondary_app_sg.id
}

##############################
# ECS Outputs
##############################

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.logicworks_cluster.id
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.app_task.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app_service.name
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

##############################
# CI/CD Outputs
##############################

# NEW: Output for GitHub Connection
output "github_connection_arn" {
  description = "The ARN of the GitHub connection for manual activation"
  value       = aws_codestarconnections_connection.github_conn.arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.app_build.name
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.pipeline.name
}

output "artifact_bucket_name" {
  description = "Name of the S3 artifact bucket"
  value       = aws_s3_bucket.artifact_bucket.bucket
}

output "sns_topic_arn" {
  description = "ARN of the SNS approval topic"
  value       = aws_sns_topic.approval_topic.arn
}



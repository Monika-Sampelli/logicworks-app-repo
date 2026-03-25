##############################
# Data Source
##############################
#data "aws_caller_identity" "current" {}

##############################
# GitHub Connection
##############################
resource "aws_codestarconnections_connection" "github_conn" {
  name          = "monika-github-connection"
  provider_type = "GitHub"
}

##############################
# SNS Notifications (Requirement 6 & 7)
##############################
resource "aws_sns_topic" "pipeline_notifications" {
  name = "logicworks-pipeline-notifications"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.pipeline_notifications.arn
  protocol  = "email"
  endpoint  = "sampellimonika@gmail.com"
}

##############################
# IAM Role for CodeBuild
##############################
resource "aws_iam_role" "codebuild_role" {
  name = "logicworks-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_role_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

resource "aws_iam_role_policy" "codebuild_extra_policy" {
  name = "logicworks-codebuild-extra-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.artifact_bucket.arn}/*"]
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

##############################
# S3 Bucket for Pipeline Artifacts
##############################
resource "aws_s3_bucket" "artifact_bucket" {
  bucket        = "logicworks-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "artifact_bucket_versioning" {
  bucket = aws_s3_bucket.artifact_bucket.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifact_bucket_encryption" {
  bucket = aws_s3_bucket.artifact_bucket.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

##############################
# CodeBuild Project
##############################
resource "aws_codebuild_project" "app_build" {
  name          = "logicworks-app-build"
  description   = "Build project for Logicworks app"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 20

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source { type = "CODEPIPELINE" }
}

##############################
# Pipeline IAM Role & Policy
##############################
resource "aws_iam_role" "pipeline_role" {
  name = "logicworks-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "pipeline_service_policy" {
  name = "logicworks-pipeline-service-policy"
  role = aws_iam_role.pipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:GetBucketVersioning", "s3:PutObject", "s3:PutObjectAcl"]
        Effect   = "Allow"
        Resource = [aws_s3_bucket.artifact_bucket.arn, "${aws_s3_bucket.artifact_bucket.arn}/*"]
      },
      {
        Action   = "codestar-connections:UseConnection"
        Effect   = "Allow"
        Resource = aws_codestarconnections_connection.github_conn.arn
      },
      {
        Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
        Effect   = "Allow"
        Resource = aws_codebuild_project.app_build.arn
      },
      {
        # FIX: Added permission to send approval emails
        Action   = "sns:Publish"
        Effect   = "Allow"
        Resource = aws_sns_topic.pipeline_notifications.arn
      },
      {
        Action   = ["ecs:*", "iam:PassRole"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

##############################
# CodePipeline
##############################
resource "aws_codepipeline" "pipeline" {
  name     = "logicworks-automation-pipeline"
  role_arn = aws_iam_role.pipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifact_bucket.bucket
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github_conn.arn
        FullRepositoryId = "Monika-Sampelli/logicworks-app-repo"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration    = { ProjectName = aws_codebuild_project.app_build.name }
    }
  }

  # Requirement 7: Manual Approval Gate
  stage {
    name = "Approval"
    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
      configuration = {
        CustomData      = "Please approve deployment to Logicworks Production"
        NotificationArn = aws_sns_topic.pipeline_notifications.arn
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]
      configuration = {
        ClusterName = aws_ecs_cluster.logicworks_cluster.name
        ServiceName = aws_ecs_service.app_service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}

##############################
# CloudWatch Monitoring (Requirement 6)
##############################
resource "aws_cloudwatch_metric_alarm" "ecs_unhealthy" {
  alarm_name          = "ecs-service-unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.pipeline_notifications.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.logicworks_cluster.name
    ServiceName = aws_ecs_service.app_service.name
  }
}

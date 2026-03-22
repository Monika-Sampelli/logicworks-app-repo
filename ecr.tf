resource "aws_ecr_repository" "app_repo" {
  provider = aws.primary
  name     = "logicworks-app"
  image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecr_replication_configuration" "replication" {
  provider = aws.primary
  replication_configuration {
    rule {
      destination {
        region      = "us-west-2"
        registry_id = data.aws_caller_identity.current.account_id
      }
    }
  }
}

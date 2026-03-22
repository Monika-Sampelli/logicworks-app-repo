# Primary AWS provider (us-east-1)
provider "aws" {
  alias   = "primary"
  region  = "us-east-1"
  profile = "default"   # replace with your AWS CLI profile name if not "default"
}

# Secondary AWS provider (us-west-2)
provider "aws" {
  alias   = "secondary"
  region  = "us-west-2"
  profile = "default"
}

# Data source to fetch current AWS account details
data "aws_caller_identity" "current" {}

terraform {
  backend "s3" {
    region         = "eu-central-1"
    bucket         = "global-tf-states"
    key            = "jenkins/terraform.tfstate"
    dynamodb_table = "lock-terraform-state"
    encrypt        = "true"
  }
}

locals {
  tags = {
    application = "jenkins"
    owner       = "terraform"
  }
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

data "aws_region" "current_region" {}

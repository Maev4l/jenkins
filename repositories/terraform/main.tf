provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      "owner"       = "terraform"
      "application" = "jenkins"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "global-tf-states"
    region         = "eu-central-1"
    key            = "jenkins/terraform.repositories.tfstate"
    encrypt        = "true"
    dynamodb_table = "lock-terraform-state"
  }
}

locals {
  repositories = [
    "jenkins/jenkins",
    "jenkins/python",
    "jenkins/nodejs"
  ]
}

resource "aws_ecr_repository" "repositories" {
  for_each     = toset(local.repositories)
  name         = each.value
  force_delete = true
}

resource "aws_ecr_lifecycle_policy" "repositories_lifecycle" {
  for_each   = aws_ecr_repository.repositories
  repository = each.value.name
  policy = jsonencode({
    "rules" : [{
      "rulePriority" : 1,
      "description" : "Expire untagged images older than 3 days",
      "selection" : {
        "tagStatus" : "untagged",
        "countType" : "sinceImagePushed",
        "countUnit" : "days",
        "countNumber" : 3
      },
      "action" : {
        "type" : "expire"
      }
    }]
  })
}

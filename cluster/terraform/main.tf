terraform {
  backend "s3" {
    region         = "eu-central-1"
    bucket         = "global-tf-states"
    key            = "jenkins/terraform.cluster.tfstate"
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

data "aws_availability_zones" "azs" {}

data "local_file" "public_key" {
  filename = pathexpand("~/.ssh/id_rsa.pub")
}

data "aws_acm_certificate" "certificate" {
  domain = "*.isnan.eu"
  types  = ["IMPORTED"]
}

resource "aws_key_pair" "public_key" {
  key_name   = "jenkins_public_key"
  public_key = data.local_file.public_key.content
}

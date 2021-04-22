terraform {
  backend "s3" {
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">3.29.1"
    }
    archive = {
      source = "hashicorp/archive"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn = local.deployer_role_arn_nullable
  }
}

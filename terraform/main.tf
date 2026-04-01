terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "devsecops-tf-state-358344803500"
    key     = "devsecops/terraform.tfstate"
    region  = "eu-north-1"
    profile = "devsecops"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "devsecops"
}
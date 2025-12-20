terraform {
  backend "s3" {
    bucket         = "reddit-terraform-state-1967814591"
    region         = "us-east-1"
    key            = "reddit-project/EKS-TF/terraform.tfstate"
    dynamodb_table = "reddit-terraform-locks"
    encrypt        = true
  }
  required_version = ">=0.13.0"
  required_providers {
    aws = {
      version = ">= 2.7.0"
      source  = "hashicorp/aws"
    }
  }
}

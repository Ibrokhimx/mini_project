terraform {
  cloud {
    organization = "pitt412"

    workspaces {
      name = "Mini_project"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
terraform {
  required_version = "1.15.5"
  backend "s3" {
    bucket       = "terraform-sandbox-764847372632-us-east-1-an"
    key          = "kafka-deploy.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.36.0"
    }
  }
}

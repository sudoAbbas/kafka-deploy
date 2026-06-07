variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "aws_region" {
  description = "The AWS region to create things in."
  type        = string
  default     = "us-east-1"
}
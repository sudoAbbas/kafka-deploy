data "aws_vpc" "sandbox_vpc" {
  tags = {
    Name = "sandbox-vpc"
  }
}

data "aws_security_group" "nat_sg" {
  tags = {
    Name = "nat-sg"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_subnets" "private_subnet" {
  filter {
    name   = "tag:Name"
    values = ["sandbox-private-*"]
  }
}
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

data "aws_subnets" "private_subnet" {
  filter {
    name   = "tag:Name"
    values = ["sandbox-private-*"]
  }
}
resource "aws_vpc" "kafka" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name = "kafka-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.kafka.id
  tags = {
    Name = "kafka-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.kafka.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-${count.index + 1}"
  }
}


resource "aws_subnet" "private" {
  count = 3

  vpc_id            = aws_vpc.kafka.id
  cidr_block        = "10.0.1${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private-${count.index + 1}"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.kafka.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}


resource "aws_route_table_association" "public" {
  count = 3

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.kafka.id

  tags = {
    Name = "private-rt"
  }
}


resource "aws_route_table_association" "private" {
  count = 3

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


resource "aws_security_group" "nat" {
  name        = "nat-sg"
  description = "NAT Instance SG"
  vpc_id      = aws_vpc.kafka.id

  ingress {
    description = "Allow traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = [
      aws_vpc.kafka.cidr_block
    ]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = ["95.145.193.210/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nat-sg"
  }
}


resource "aws_instance" "nat" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.nano"
  key_name = "abbas"

  subnet_id = aws_subnet.public[0].id

  vpc_security_group_ids = [
    aws_security_group.nat.id
  ]

  associate_public_ip_address = true

  source_dest_check = false

  user_data = <<-EOF
#!/bin/bash

sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

dnf install -y iptables-services

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

service iptables save
systemctl enable iptables
EOF

  tags = {
    Name = "nat-instance"
  }
}


resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id = aws_instance.nat.primary_network_interface_id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.kafka.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "s3-endpoint"
  }
}

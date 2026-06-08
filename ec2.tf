resource "aws_instance" "kafka" {
  count         = 3
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.nano"

  subnet_id              = data.aws_subnets.private_subnet.ids[count.index]
  vpc_security_group_ids = [aws_security_group.kafka.id]

  iam_instance_profile = aws_iam_instance_profile.kafka.name

  root_block_device {
    volume_size = 50
  }

  tags = {
    Name = "kafka-${count.index + 1}"
  }
}

resource "aws_ebs_volume" "kafka_data" {
  count             = 3
  availability_zone = aws_instance.kafka[count.index].availability_zone
  size              = 5
  type              = "gp3"

  tags = {
    Name = "kafka-data-${count.index + 1}"
  }
}
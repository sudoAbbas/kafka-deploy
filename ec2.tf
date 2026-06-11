resource "aws_instance" "kafka" {
  count                  = 3
  ami                    = "ami-0e25c98f8f1e341e9"
  instance_type          = "t3.small"
  key_name               = "abbas"
  subnet_id              = data.aws_subnets.private_subnet.ids[count.index]
  vpc_security_group_ids = [aws_security_group.kafka.id]
  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "enabled"

  }
  iam_instance_profile = aws_iam_instance_profile.kafka.name

  root_block_device {
    volume_size = 50
  }

  tags = {
    Name    = "kafka-${count.index + 1}",
    NODE_ID = "${count.index + 1}"
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

resource "aws_volume_attachment" "kafka_data" {
  count = 3

  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.kafka_data[count.index].id
  instance_id = aws_instance.kafka[count.index].id
}
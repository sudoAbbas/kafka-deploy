resource "aws_route53_zone" "kafka" {
  name = "kafka.internal"

  vpc {
    vpc_id = data.aws_vpc.sandbox_vpc.id
  }

  comment = "Private hosted zone for Kafka brokers"

  tags = {
    Name = "kafka-private-zone"
  }
}

resource "aws_route53_record" "kafka" {
  count = length(aws_instance.kafka)

  zone_id = aws_route53_zone.kafka.zone_id

  name = "kafka-${count.index + 1}"
  type = "A"
  ttl  = 300

  records = [
    aws_instance.kafka[count.index].private_ip
  ]
}

resource "aws_route53_record" "kafka_bootstrap" {
  zone_id = aws_route53_zone.kafka.zone_id

  name = "bootstrap"
  type = "A"
  ttl  = 300

  records = [
    aws_instance.kafka[0].private_ip,
    aws_instance.kafka[1].private_ip,
    aws_instance.kafka[2].private_ip
  ]
}
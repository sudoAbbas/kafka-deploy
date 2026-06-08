resource "aws_security_group" "kafka" {
  name        = "kafka-sg"
  vpc_id      = data.aws_vpc.sandbox_vpc.id
  description = "Kafka brokers security groups"
  tags = {
    Name = "kafka-sg"
  }
}
resource "aws_security_group_rule" "kafka_client_ingress" {
  description       = "Allow Kafka client connections from resources within the VPC"
  type              = "ingress"
  from_port         = 9092
  to_port           = 9092
  protocol          = "tcp"
  security_group_id = aws_security_group.kafka.id
  cidr_blocks       = [data.aws_vpc.sandbox_vpc.cidr_block]
}

resource "aws_security_group_rule" "kafka_broker_ingress" {
  description              = "Allow Kafka brokers to communicate with each other on the broker listener"
  type                     = "ingress"
  from_port                = 9092
  to_port                  = 9092
  protocol                 = "tcp"
  security_group_id        = aws_security_group.kafka.id
  source_security_group_id = aws_security_group.kafka.id
}

resource "aws_security_group_rule" "kraft_controller_ingress" {
  description              = "Allow KRaft controller communication between Kafka brokers"
  type                     = "ingress"
  from_port                = 9093
  to_port                  = 9093
  protocol                 = "tcp"
  security_group_id        = aws_security_group.kafka.id
  source_security_group_id = aws_security_group.kafka.id
}

resource "aws_security_group_rule" "kafka_ssh_from_nat" {
  description              = "Allow SSH access to Kafka brokers from the NAT instance"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.kafka.id
  source_security_group_id = data.aws_security_group.nat_sg.id
}

resource "aws_security_group_rule" "kafka_egress" {
  description       = "Allow outbound traffic for package updates, DNS resolution and AWS service communication"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.kafka.id
  cidr_blocks       = ["0.0.0.0/0"]
}
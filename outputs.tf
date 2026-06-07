output "vpc_id" {
  value = aws_vpc.kafka.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "availability_zones" {
  value = data.aws_availability_zones.available.names
}
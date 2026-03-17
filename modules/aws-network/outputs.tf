output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the AWS VPC"
}

output "subnet_id_a" {
  value       = aws_subnet.public_a.id
  description = "ID of public subnet in AZ-a"
}

output "subnet_id_b" {
  value       = aws_subnet.public_b.id
  description = "ID of public subnet in AZ-b"
}

output "rds_security_group_id" {
  value       = aws_security_group.rds_sg.id
  description = "ID of the Security Group permitting MySQL (3306) access to RDS"
}

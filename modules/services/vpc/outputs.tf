output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The ID of the VPC"
}

output "cidr_block" {
  value       = aws_vpc.this.cidr_block
  description = "The CIDR block of the VPC"
}

output "public_subnet_ids" {
  value       = concat(aws_subnet.public_subnets.*.id, [aws_subnet.public_subnet_other_az.id])
  description = "IDs of all public subnets"
}

output "private_subnet_ids" {
  value       = concat(aws_subnet.private_subnets.*.id, [aws_subnet.private_subnet_other_az.id])
  description = "IDs of all private subnets"
}

output "private_subnet_ids_different_zones" {
  value       = concat([aws_subnet.private_subnets[0].id], [aws_subnet.private_subnet_other_az.id])
  description = "One private subnet ID per availability zone"
}

output "nat_gw_ip" {
  value       = aws_nat_gateway.this.public_ip
  description = "The public IP of the NAT gateway"
}

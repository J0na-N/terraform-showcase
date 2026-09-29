output "cluster_alb_dns_name" {
  value       = module.webserver_cluster.alb_dns_name
  description = "The domain name of the load balancer for the cluster"
}

output "single_instance_public_ip" {
  value       = module.webserver_instance.public_ip
  description = "The public IP address of the single web server"
}

output "cluster_asg_name" {
  value       = module.webserver_cluster.asg-name
  description = "The name of the Auto Scaling Group"
}

output "single_instance_id" {
  value       = module.webserver_instance.instance_id
  description = "The ID of the single EC2 instance"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC"
}

output "vpc_public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "IDs of the VPC public subnets"
}

output "vpc_private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "IDs of the VPC private subnets"
}

output "vpc_nat_gateway_ip" {
  value       = module.vpc.nat_gw_ip
  description = "The public IP of the VPC NAT gateway"
}

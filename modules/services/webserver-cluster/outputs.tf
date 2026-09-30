output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}

# we need this output for the autoscaling_group_name parameter
output "asg-name" {
  value       = aws_autoscaling_group.example.name
  description = "The name of the Auto Scaling Group"
}

output "alb-dns-name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}

output "alb-security-group-id" {
  value       = aws_security_group.alb.id
  description = "The ID of the Security Group attached to the load balancer"
}



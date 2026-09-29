# ------------------------------
# deploying a cluster of servers
# ------------------------------

locals {
  http-port     = 80
  any-port      = 0
  any-protocol  = "-1"
  all-ips       = ["0.0.0.0/0"]
  tcp-protocol  = "tcp"
  server-port   = 8080
  http-protocol = "HTTP"
}

# these are the configurations that will be used to create the cluster
resource "aws_launch_configuration" "example" {
  image_id        = "ami-0fb653ca2d3203ac1"
  instance_type   = var.instance-type
  security_groups = [aws_security_group.cluster-instance.id]

  user_data = templatefile("${path.module}/user-data.sh", {
    server_port = local.server-port
    server-text = var.server-text
  })

  # aws_launch_configuration is an immutable object
  # if we change the launch configuration Terraform will attempt to replace it entirely
  # replace ~= destroy then create
  # Terraform won't be able to destroy the old launch configuration
  # because our asg has a reference to the old launch configuration 
  # so we change the Terraform behavior to create first and then destroy
  lifecycle {
    create_before_destroy = true # now we can change the launch configurations
  }
}

# the autoscaling group represents our cluster
resource "aws_autoscaling_group" "example" {
  # name depends on the launch configuration
  # when launch configuration changes so does the asg name
  # this forces Terraform to replace the asg with new instances 
  # every time the launch configurationb is modified
  # name                 = "${aws_launch_configuration.example.name}-jona-asg"

  name                 = "${var.cluster-name}-jona-asg"
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = var.private-subnet-ids # instances run in the private subnets
  desired_capacity     = 3

  target_group_arns = [aws_lb_target_group.asg.arn] # ARN - Amazon Resource Name
  health_check_type = "ELB"                         # default type is EC2 (minimal check: is the instance unreachable?)
  # ELB is more robust
  # uses target group's health check
  # e.g. replace if instance is out of memory or has crashed

  min_size = var.min-size
  max_size = var.max-size

  # wait for at least these many instances to pass health checks
  # before considering the asg deployment complete
  # min_elb_capacity = var.min-size

  # create replacement first, and then delete the original asg
  # lifecycle {
  #   create_before_destroy = true
  # }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}

# AWS does not allow any incoming or outgoing traffic from an EC2 instance
# so we need to create a Security Group to handle traffic on port 8080.
# Instances live in private subnets, so we only accept traffic from the ALB.
resource "aws_security_group" "cluster-instance" {
  name        = "${var.cluster-name}-instance-sg"
  description = "Allow app traffic from the load balancer only"
  vpc_id      = var.vpc-id
}

# Allow the app port (8080) inbound only from the ALB security group.
resource "aws_security_group_rule" "instance-allow-from-alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.cluster-instance.id
  from_port                = local.server-port
  to_port                  = local.server-port
  protocol                 = local.tcp-protocol
  source_security_group_id = aws_security_group.alb.id
}

# Allow all outbound so instances can reach the internet via the NAT gateway
# (package updates, etc.).
resource "aws_security_group_rule" "instance-allow-all-outbound" {
  type              = "egress"
  security_group_id = aws_security_group.cluster-instance.id
  from_port         = local.any-port
  to_port           = local.any-port
  protocol          = local.any-protocol
  cidr_blocks       = local.all-ips
}

moved {
  from = aws_security_group.instance
  to   = aws_security_group.cluster-instance
}

# EC2 instances on a cluster all have unique IPs (bad)
# we need deploy a load balancer to distribute traffic across our servers 
# and to give all users the IP (DNS name) of the load balancer
resource "aws_lb" "example" {
  name               = "${var.cluster-name}-lb"
  load_balancer_type = "application"
  subnets            = var.public-subnet-ids       # internet-facing ALB lives in the public subnets
  security_groups    = [aws_security_group.alb.id] # use the alb security group
}

# configuring the lb to:
## listen on the default HTTP port (80)
## use HTTP protocol
## send a 404 page for requests that do not match any listener rules
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.http-port
  protocol          = local.http-protocol

  # return a simple 404 page by default
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found :("
      status_code  = 404
    }
  }
}

# handling incoming and outgoing traffic for the Application Load Balancer
# default: no traffic is allowed
resource "aws_security_group" "alb" {
  name   = "${var.cluster-name}-alb-sg"
  vpc_id = var.vpc-id
}

# allowing incoming HTTP requests on port 80
# to access the load balancer over HTTP
resource "aws_security_group_rule" "allow-http-inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http-port
  to_port     = local.http-port
  protocol    = local.tcp-protocol
  cidr_blocks = local.all-ips
}

# allowing outbound requests on all ports
# to perform health checks
resource "aws_security_group_rule" "allow-all-out-bound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any-port
  to_port     = local.any-port
  protocol    = local.any-protocol
  cidr_blocks = local.all-ips
}

# configuring my ASG as the target group of the Application Load Balancer
resource "aws_lb_target_group" "asg" {
  name     = "${var.cluster-name}-asg"
  port     = local.server-port
  protocol = local.http-protocol
  vpc_id   = var.vpc-id

  # this target group will health-check our instances
  # it will send http requests periodically to each instance in our asg
  health_check {
    path                = "/"
    protocol            = local.http-protocol
    matcher             = "200" # the instance is healthy if its response is the same as the matcher (200 OK response)
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  # if an instance fails to respond, it will be marked as unhealthy 
  # the target group will stop sending requests to that instance
}

# listener rule:
# send requests that match any path to the target group containing our asg
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# changing the size of the cluster depending on the time of day
# increase the number of servers at 09:00
resource "aws_autoscaling_schedule" "scale-out-business-hrs" {
  count                  = var.enable-autoscaling ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.example.name

  scheduled_action_name = "scale-out-business-hrs"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 10
  recurrence            = "0 9 * * *"
}

# decrease the number of servers at 17:00
resource "aws_autoscaling_schedule" "scale-in-at-night" {
  count                  = var.enable-autoscaling ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.example.name

  scheduled_action_name = "scale-in-at-night"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "0 17 * * *"
}

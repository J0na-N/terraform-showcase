# ------------------------------
# deploying a single EC2 server
# ------------------------------

locals {
  server-port  = 8080
  tcp-protocol = "tcp"
  all-ips      = ["0.0.0.0/0"]
}

resource "aws_instance" "example" {
  ami                    = var.ami
  instance_type          = var.instance-type
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = templatefile("${path.module}/user-data.sh", {
    server_port = local.server-port
    server-text = var.server-text
  })
}

resource "aws_security_group" "instance" {
  name = "${var.instance-name}-sg"

  ingress {
    from_port   = local.server-port
    to_port     = local.server-port
    protocol    = local.tcp-protocol
    cidr_blocks = local.all-ips
  }
}
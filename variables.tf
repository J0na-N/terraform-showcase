variable "cluster_name" {
  description = "The name to use for the webserver cluster"
  type        = string
  default     = "webservers"
  sensitive   = true
}

variable "cluster_instance_type" {
  description = "The type of EC2 instances to run in the cluster"
  type        = string
  default     = "t2.micro"
  sensitive   = true
}

variable "min_size" {
  description = "The minimum number of EC2 instances in the ASG"
  type        = string
  default     = "2"
  sensitive   = true
}

variable "max_size" {
  description = "The maximum number of EC2 instances in the ASG"
  type        = string
  default     = "10"
  sensitive   = true
}

variable "enable_autoscaling" {
  description = "If set to true, enable automatic scaling"
  type        = bool
  default     = false
  sensitive   = true
}

variable "server_text" {
  description = "The text the web servers should return"
  type        = string
  default     = "Hello, World!"
  sensitive   = true
}

variable "instance_name" {
  description = "The name to use for the single webserver instance"
  type        = string
  default     = "single-webserver"
  sensitive   = true
}

variable "single_instance_type" {
  description = "The type of EC2 instance to run for the single server"
  type        = string
  default     = "t2.micro"
  sensitive   = true
}

# --- Provider / shared ---

variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-2"
  sensitive   = true
}

variable "environment" {
  description = "The environment being deployed (e.g. dev, staging, prod). Controls VPC flow-log retention and traffic type."
  type        = string
  default     = "dev"
  sensitive   = true
}

# --- VPC module ---

variable "vpc_nametag" {
  description = "Name tag prefix applied to every resource in the VPC module"
  type        = string
  default     = "webservers"
  sensitive   = true
}

variable "vpc_cidr_block" {
  description = "The CIDR range of the VPC"
  type        = string
  default     = "10.0.0.0/16"
  sensitive   = true
}

variable "vpc_ssh_allowed_cidrs" {
  description = "CIDR blocks allowed SSH (port 22) access through the VPC default network ACL"
  type        = list(string)
  default     = ["178.132.223.13/32"]
  sensitive   = true
}

variable "cluster-name" {
  description = "The name to use for all cluster resources"
  type        = string
}

variable "vpc-id" {
  description = "ID of the VPC to deploy the cluster into"
  type        = string
}

variable "public-subnet-ids" {
  description = "Public subnet IDs where the load balancer will be placed"
  type        = list(string)
}

variable "private-subnet-ids" {
  description = "Private subnet IDs where the ASG instances will be placed"
  type        = list(string)
}

variable "instance-type" {
  description = "The type of EC2 instances to run (e.g. t2.micro for staging, t2.medium for production)"
  type        = string
}

variable "min-size" {
  description = "The minimum number of EC2 instances in the ASG"
  type        = string
}

variable "max-size" {
  description = "The maximum number of EC2 instances in the ASG"
  type        = string
}

variable "test" {
  type = string
}

variable "enable-autoscaling" {
  description = "If set to true, enable automatic scaling"
  type        = bool
}

variable "ami" {
  description = "The AMI to run in the cluster"
  type        = string
  default     = "ami-0fb653ca2d3203ac1"
}

variable "server-text" {
  description = "The text the web server should return"
  type        = string
  default     = "Hello, World!"
}

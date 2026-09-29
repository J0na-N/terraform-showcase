variable "nametag" {
  description = "Name tag prefix applied to every resource in this module"
  type        = string
  nullable    = false
}

variable "environment" {
  description = "The environment this VPC belongs to (e.g. dev, staging, prod)"
  type        = string
  nullable    = false
}

variable "region" {
  description = "AWS region used to build VPC endpoint service names"
  type        = string
  nullable    = false
}

variable "vpc-cidr-block" {
  description = "The CIDR range of the VPC"
  type        = string
  default     = "10.0.0.0/16"
  nullable    = false
}

variable "public-subnet-cidrs" {
  description = "Public subnet CIDRs in the primary availability zone"
  type        = list(string)
  default     = ["10.0.0.0/19", "10.0.32.0/19"]
  nullable    = false
}

variable "private-subnet-cidrs" {
  description = "Private subnet CIDRs in the primary availability zone"
  type        = list(string)
  default     = ["10.0.64.0/19", "10.0.96.0/19"]
  nullable    = false
}

variable "private-subnet-cidrs-other-az" {
  description = "Private subnet CIDRs in the secondary availability zone"
  type        = list(string)
  default     = ["10.0.128.0/19"]
  nullable    = false
}

variable "public-subnet-cidrs-other-az" {
  description = "Public subnet CIDRs in the secondary availability zone"
  type        = list(string)
  default     = ["10.0.160.0/19"]
  nullable    = false
}

variable "subnet-availability-zones" {
  description = "Availability zones for the subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  nullable    = false
}

variable "ssh-allowed-cidrs" {
  description = "CIDR blocks allowed SSH (port 22) access through the default network ACL. Traffic from all other sources is denied."
  type        = list(string)
  default     = ["178.132.223.13/32"]
  nullable    = false
}

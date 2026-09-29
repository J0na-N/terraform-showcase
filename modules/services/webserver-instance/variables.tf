variable "instance-name" {
  description = "The name to use for the instance"
  type        = string
}

variable "instance-type" {
  description = "The type of EC2 instance to run"
  type        = string
  default     = "t2.micro"
}

variable "ami" {
  description = "The AMI to run"
  type        = string
  default     = "ami-0fb653ca2d3203ac1"
}

variable "server-text" {
  description = "The text the web server should return"
  type        = string
  default     = "Hello, World!"
}
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "your-terraform-state-bucket-name"
    key     = "webservers/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      CreatedBy = "Terraform"
    }
  }
}

module "webserver_cluster" {
  source = "./modules/services/webserver-cluster"

  cluster-name       = var.cluster_name
  instance-type      = var.cluster_instance_type
  min-size           = var.min_size
  max-size           = var.max_size
  enable-autoscaling = var.enable_autoscaling
  server-text        = var.server_text
  test               = "test"

  # Deploy into the new VPC: ALB in public subnets, instances in private subnets.
  vpc-id             = module.vpc.vpc_id
  public-subnet-ids  = module.vpc.public_subnet_ids
  private-subnet-ids = module.vpc.private_subnet_ids
}

module "webserver_instance" {
  source = "./modules/services/webserver-instance"

  instance-name = var.instance_name
  instance-type = var.single_instance_type
  server-text   = var.server_text
}

module "vpc" {
  source = "./modules/services/vpc"

  nametag     = var.vpc_nametag
  environment = var.environment
  region      = var.aws_region

  vpc-cidr-block    = var.vpc_cidr_block
  ssh-allowed-cidrs = var.vpc_ssh_allowed_cidrs
}
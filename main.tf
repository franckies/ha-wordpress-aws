terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}

#============================== NETWORKING =====================================
# VPC module provision a new Elastic IP each time the VPC is destroyed and
# re-allocated. We create an EIP once to always be the same.
#VPC - Internet Gateway - Subnets
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "ha-wordpress"
  cidr = "192.168.0.0/16"
  # eu-west-1 supports 3 AZs
  azs             = ["eu-west-1a", "eu-west-1b"]
  # subnets
  private_subnets = ["192.168.2.0/24", "192.168.3.0/24"]
  intra_subnets= ["192.168.4.0/24", "192.168.5.0/24"]
  public_subnets  = ["192.168.0.0/24", "192.168.1.0/24"]

  enable_vpn_gateway = true
  
  enable_nat_gateway  = true
  single_nat_gateway  = false #enable one NAT gateway per AVz
  one_nat_gateway_per_az = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

#============================== DATABASE =======================================
# Security groups for RDS
resource "aws_security_group" "wp-db-client-sg" {
  name = "wp-db-client-sg"

  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group" "wp-db-sg" {
  name = "wp-db-sg"

  description = "Allow TCP connection on 3306 for RDS"
  vpc_id      = module.vpc.vpc_id

  # Only MySQL in
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.wp-db-client-sg.id]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}

#RDS Database
module "db" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 3.0"

  name           = "wordpress"
  engine         = "aurora-postgresql"
  engine_version = "11.9"
  instance_type  = "db.r5.large"

  vpc_id  = module.vpc.vpc_id
  subnets =  module.vpc.intra_subnets

  replica_count           = 2
  allowed_security_groups = [aws_security_group.wp-db-sg.id]

  storage_encrypted   = true
  apply_immediately   = true
  monitoring_interval = 10

  db_parameter_group_name = "ha-wordpress"

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}


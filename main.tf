#============================= PROVIDER CONFIG =================================
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
################################################################################
# VPC, Internet Gateway, Subnets Module
################################################################################
# VPC module provision a new Elastic IP each time the VPC is destroyed and
# re-allocated. We create an EIP once to always be the same.
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
################################################################################
# Security Groups
################################################################################
resource "aws_security_group" "wp-db-client-sg" {
  name = "wp-db-client-sg"

  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group" "wp-db-sg" {
  name        = "wp-db-sg"

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

################################################################################
# RDS Aurora Module
################################################################################
module "aurora" {
  source                          = "git::git@github.com:deliveryhero/tf-aws-rds-aurora.git"
  name                            = "aurora-example-mysql"
  engine                          = "aurora-mysql"
  engine_version                  = "5.7.12"
  subnet_ids                      = module.vpc.intra_subnets
  #azs                             = ["eu-west-1a", "eu-west-1b"]
  vpc_id                          = module.vpc.vpc_id
  replica_count                   = 1
  instance_type                   = "db.t2.medium"
  apply_immediately               = true
  skip_final_snapshot             = true
  db_parameter_group_name         = aws_db_parameter_group.aurora_db_57_parameter_group.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_57_cluster_parameter_group.id

   tags = {
      Environment = "dev"
     Terraform   = "true"
   }

}

resource "aws_db_parameter_group" "wordpress" {
  name        = "wordpress"
  family      = "aurora-mysql5.7"
}

resource "aws_rds_cluster_parameter_group" "ha-wordpress" {
  name        = "ha-wordpress"
  family      = "aurora-mysql5.7"
}
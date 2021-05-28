################################################################################
# VPC, Internet Gateway, Subnets Module
################################################################################
# VPC module provision a new Elastic IP each time the VPC is destroyed and
# re-allocated. We create an EIP once to always be the same.
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr
  azs = var.azs
  # subnets
  private_subnets = var.private_subnets
  intra_subnets   = var.intra_subnets
  public_subnets  = var.public_subnets

  enable_vpn_gateway = true

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  #enable dns resolution support
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
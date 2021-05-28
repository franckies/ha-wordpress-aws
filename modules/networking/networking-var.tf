variable "vpc_name" {
  type         = string
  default      = "wordpress-vpc"
  description  = "The name of the VPC"
}
variable "vpc_cidr" {
    type        = string
    default     = "192.168.0.0/16"
    description = "The CIDR of the VPC."
}
variable "azs" {
    type        = list(string)
    default     = ["eu-west-1a", "eu-west-1b"]
    description = "The Availability zones in which the infra will be deployed."
}
variable "private_subnets" {
    type        = list(string)
    default     = ["192.168.2.0/24", "192.168.3.0/24"]
    description = "Private subnets CIDR (one per az), where the application servers will be deployed"
}
variable "public_subnets" {
    type        = list(string)
    default     = ["192.168.0.0/24", "192.168.1.0/24"]
    description = "Public subnets CIDR (one per az), where the load balancer will be deployed"
}
variable "intra_subnets" {
    type        = list(string)
    default     = ["192.168.4.0/24", "192.168.5.0/24"]
    description = "Intra subnets CIDR (one per az), where the databases will be deployed"
}

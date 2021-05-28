variable "vpc_id" {
  description = "The ID of the VPC."
}

variable "public_subnets" {
  description = "The public subnets ids."
}

variable "intra_subnets" {
  description = "The intra subnets ids."
}

variable "private_subnets" {
  description = "The private subnets ids."
}

variable "efs_dns_name" {
  description = "The DNS name of EFS"
}

variable "db_name" {
  description = "The name of RDS database"
}

variable "db_hostname" {
  description = "The DNS name of RDS"
}

variable "db_username" {
  description = "Database username"
}

variable "db_password" {
  description = "Database password"
}

variable "clients_sg" {
  description = "The security group ids of data layer clients"
}

variable "prefix_name" {
    type         = string
    default      = "wordpress-app"
    description  = "Prefix name for application layer"
}

variable "http_port" {
    type         = number
    default      = 80
    description  = "The http port"
}

variable "https_port" {
    type         = number
    default      = 443
    description  = "The http port"
}

variable "ssh_port" {
    type         = number
    default      = 22
    description  = "The ssh port"
}

variable "key_name" {
    type         = string
    default      = "ec2-hawordpress"
    description  = "The name of private key to access the VMs through SSH"
}

variable "ami" {
    type         = string
    default      = "ami-038d7b856fe7557b3"
    description  = "The AMI to build up the VMs, default is ubuntu 16.04"
}

variable "vm_instance_type" {
    type         = string
    default      = "t2.small"
    description  = "The VMs type within the AutoScalingGroup"
}

variable "asg_min_size" {
    type         = number
    default      = 2
    description  = "Minimum number of VMs within the ASG"
}

variable "asg_max_size" {
    type         = number
    default      = 8
    description  = "Maximum number of VMs within the ASG"
}


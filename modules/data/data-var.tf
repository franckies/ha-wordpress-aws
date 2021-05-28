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

variable "rds_port" {
    type         = number
    default      = 3306
    description  = "RDS Database port"
}

variable "prefix_name" {
    type         = string
    default      = "wordpress-data"
    description  = "Prefix name for data layer"

}

variable "rds_instance_class" {
    type         = string
    default      = "db.r5.large"
    description  = "The instance class for RDS instances"
}

variable "cluster_dbname" {
    type         = string
    default      = "wordpress"
    description  = "The RDS cluster database name"
}

variable "cluster_username" {
    type         = string
    default      = "username"
    description  = "The RDS cluster username"
}

variable "cluster_password" {
    type         = string
    default      = "password"
    description  = "The RDS cluster password"
}

variable "rds_instance_count" {
    type         = number
    default      = 2
    description  = "The number of RDS instances to launch, it should match the number of azs"
}

variable "memcached_port" {
    type         = number
    default      = 11211
    description  = "Memcached Database port"
}

variable "memcached_node_type" {
    type         = string
    default      = "cache.t2.small"
    description  = "Node type for elasticache cluster"
}

variable "memcached_nodes_count" {
    type         = number
    default      = 1
    description  = "The number of cache nodes"
}

variable "efs_port" {
    type         = number
    default      = 2049
    description  = "Elastic File System port"
}




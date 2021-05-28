################################################################################
# Security groups for Elasticache
################################################################################
resource "aws_security_group" "wordpress-cache-client-sg" {
  name = "${var.prefix_name}-memcached-client-sg"

  description = "Allow wordpress servers to contact elasticache on 11211"
  vpc_id = var.vpc_id

  egress {
    from_port = var.memcached_port
    to_port   = var.memcached_port
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.prefix_name}-memcached-client-sg"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "wordpress-cache-sg" {
  name = "${var.prefix_name}-memcached-sg"

  description = "Allow TCP connection on 11211 for Elasticache"
  vpc_id      = var.vpc_id

  # Only cache in
  ingress {
    from_port       = var.memcached_port
    to_port         = var.memcached_port
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress-cache-client-sg.id]
  }

   egress {
    from_port = var.memcached_port
    to_port   = var.memcached_port
    protocol  = "tcp"

    security_groups = [aws_security_group.wordpress-cache-client-sg.id]
  }

    tags = {
    Name        = "${var.prefix_name}-memcached-sg"
    Terraform   = "true"
    Environment = "dev"
  }
}
################################################################################
# Elasticache Memcached
################################################################################
resource "aws_elasticache_cluster" "wordpress-memcached" {
  cluster_id           = "${var.prefix_name}-memcached-cluster"
  engine_version       = "1.5.16"
  subnet_group_name    = aws_elasticache_subnet_group.wordpress-elasticache.name
  security_group_ids   = [aws_security_group.wordpress-cache-sg.id]
  engine               = "memcached"
  node_type            = var.memcached_node_type
  num_cache_nodes      = var.memcached_nodes_count
  parameter_group_name = "default.memcached1.5"
  port                 = var.memcached_port

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
################################################################################
# Subnet Group
################################################################################
resource "aws_elasticache_subnet_group" "wordpress-elasticache" {
  name        = "${var.prefix_name}-memcached-subnetgroup"
  description = "Subnet group used by elasticache"
  subnet_ids  = var.intra_subnets

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
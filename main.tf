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
  azs = ["eu-west-1a", "eu-west-1b"]
  # subnets
  private_subnets = ["192.168.2.0/24", "192.168.3.0/24"]
  intra_subnets   = ["192.168.4.0/24", "192.168.5.0/24"]
  public_subnets  = ["192.168.0.0/24", "192.168.1.0/24"]

  enable_vpn_gateway = true

  enable_nat_gateway     = true
  single_nat_gateway     = false #enable one NAT gateway per AVz
  one_nat_gateway_per_az = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


#============================== DATA TIER ======================================

#============================== DATABASE =======================================
################################################################################
# Security Groups for RDS
################################################################################
resource "aws_security_group" "wordpress-db-client-sg" {
  name = "wordpress-db-client-sg"

  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "wordpress-db-sg" {
  name = "wordpress-db-sg"

  description = "Allow TCP connection on 3306 for RDS"
  vpc_id      = module.vpc.vpc_id

  # Only MySQL in
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress-db-client-sg.id]
  }

  # Allow all outbound traffic.
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
  }
}
################################################################################
# Subnet Group
################################################################################
resource "aws_db_subnet_group" "wordpress-aurora" {
  name        = "wordpress-aurora"
  subnet_ids  = module.vpc.intra_subnets
  description = "Subnet group used by Aurora DB"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
################################################################################
# RDS Database
################################################################################
resource "aws_rds_cluster" "wordpress-rds-cluster" {
  cluster_identifier     = "wordpress-workshop"
  engine                 = "aurora-mysql"
  engine_version         = "5.7.mysql_aurora.2.07.2"
  #availability_zones     = ["eu-west-1a", "eu-west-1b"] #causes every time to destroy and rebuild rds cluster
  database_name          = "wordpress"
  db_subnet_group_name   = aws_db_subnet_group.wordpress-aurora.name
  master_username        = "wordpressadmin"
  master_password        = "wordpressadminn"
  vpc_security_group_ids = [aws_security_group.wordpress-db-sg.id]
  skip_final_snapshot    = true
  #backup_retention_period = 5
  #preferred_backup_window = "07:00-09:00"
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

#RDS Cluster Instance
resource "aws_rds_cluster_instance" "wordpress-rds-instances" {
  count                = 2
  identifier           = "database-1-instance-${count.index}"
  db_subnet_group_name = aws_db_subnet_group.wordpress-aurora.name
  cluster_identifier   = aws_rds_cluster.wordpress-rds-cluster.id
  instance_class       = "db.r5.large"
  engine               = aws_rds_cluster.wordpress-rds-cluster.engine
  engine_version       = aws_rds_cluster.wordpress-rds-cluster.engine_version
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

#============================= ELASTICACHE =====================================
################################################################################
# Security groups for Elasticache
################################################################################
resource "aws_security_group" "wordpress-cache-client-sg" {
  name = "wordpress-cache-client-sg"

  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "wordpress-cache-sg" {
  name = "wordpress-cache-sg"

  description = "Allow TCP connection on 11211 for Elasticache"
  vpc_id      = module.vpc.vpc_id

  # Only cache in
  ingress {
    from_port       = 11211
    to_port         = 11211
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress-cache-client-sg.id]
  }

  # Allow all outbound traffic.
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
  }
}
################################################################################
# Elasticache Memcached
################################################################################
resource "aws_elasticache_cluster" "wordpress-memcached" {
  cluster_id           = "wordpress-memcached"
  engine_version       = "1.5.16"
  subnet_group_name    = aws_elasticache_subnet_group.wordpress-elasticache.name
  security_group_ids   = [aws_security_group.wordpress-cache-sg.id]
  engine               = "memcached"
  node_type            = "cache.t2.small"
  num_cache_nodes      = 1
  parameter_group_name = "default.memcached1.5"
  port                 = 11211

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
################################################################################
# Subnet Group
################################################################################
resource "aws_elasticache_subnet_group" "wordpress-elasticache" {
  name        = "wordpress-elasticache"
  description = "Subnet group used by elasticache"
  subnet_ids  = module.vpc.intra_subnets

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

#============================== SHARED FS ======================================
################################################################################
# Security groups for Elastic File System
################################################################################
resource "aws_security_group" "wordpress-fs-client-sg" {
  name = "wordpress-fs-client-sg"

  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "wordpress-fs-sg" {
  name = "wordpress-fs-sg"

  description = "Allow TCP connection on 2049  for Elastic File System"
  vpc_id      = module.vpc.vpc_id

  # Only efs in
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress-fs-client-sg.id]
  }

  # Allow all outbound traffic.
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
  }
}

################################################################################
# Elastic File System
################################################################################
resource "aws_efs_file_system" "wordpress-efs" {
  creation_token = "wordpress-efs"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_efs_mount_target" "wordpress-mount-targets" {
  count           = length(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.wordpress-efs.id
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.wordpress-fs-sg.id]
}

#=============================== APP TIER ======================================

#============================= LOAD BALANCER ===================================
################################################################################
# Security groups for Load Balancer
################################################################################
resource "aws_security_group" "wordpress-lb-sg" {
  name = "wordpress-lb-sg"

  description = "Allow HTTP connection from everywhere"
  vpc_id      = module.vpc.vpc_id

  # Accept from everywhere
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################################
# Load Balancer
################################################################################
# resource "aws_alb" "wordpress-loadbalancer" {
#   name               = "wordpress-loadbalancer"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.wordpress-lb-sg.id]
#   subnets            = aws_subnet.public.*.id
#   ip_address_type    = "ipv4"

#   #enable_deletion_protection = true

#   tags = {
#     Terraform = "true"
#     Environment = "dev"
#   }
# }

# resource "aws_alb_target_group" "wordpress-targetgroup" {
#   name     = "wordpress-targetgroup"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = module.vpc.vpc_id
# }
resource "aws_alb" "wordpress-loadbalancer" {

  name               = "wordpress-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.wordpress-lb-sg.id]
  subnets            = module.vpc.public_subnets
  tags = {
      Terraform = "true"
      Environment = "dev"
    }
}

resource "aws_alb_listener" "wordpress-lb-listener" {
  load_balancer_arn = aws_alb.wordpress-loadbalancer.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.wordpress-lb-target-group.arn
  }
}

resource "aws_alb_target_group" "wordpress-lb-target-group" {
  name     = "wordpress-lb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  health_check {    
    target              = "HTTP:80/"
    healthy_threshold   = 3    
    unhealthy_threshold = 10    
    timeout             = 5    
    interval            = 10    
    port                = 80 
  }
  tags = {
      Terraform = "true"
      Environment = "dev"
    }
}
# module "alb" {
#   source  = "terraform-aws-modules/alb/aws"
#   version = "~> 6.0"

#   name = "wordpress-loadbalancer"

#   load_balancer_type = "application"

#   vpc_id          = module.vpc.vpc_id
#   subnets         = module.vpc.public_subnets
#   security_groups = [aws_security_group.wordpress-lb-sg.id]

#   target_groups = [
#     {
#       name_prefix      = "wp-tg-"
#       backend_protocol = "HTTP"
#       backend_port     = 80
#       target_type      = "instance"
#       targets = [
#         # {
#         #   target_id = "i-0123456789abcdefg"
#         #   port      = 80
#         # },
#         # {
#         #   target_id = "i-a1b2c3d4e5f6g7h8i"
#         #   port      = 8080
#         # }
#       ]
#     }
#   ]

#   http_tcp_listeners = [
#     {
#       port               = 80
#       protocol           = "HTTP"
#       target_group_index = 0
#     }
#   ]

#   tags = {
#     Terraform = "true"
#     Environment = "dev"
#   }
# }
#============================ WordPress Servers ================================
################################################################################
# Security groups for WordPress Server
################################################################################
resource "aws_security_group" "wordpress-servers-sg" {
  name = "wordpress-servers-sg"

  description = "Allow HTTP connection from Load Balancer"
  vpc_id      = module.vpc.vpc_id

  # Only lb in http & https
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups = [aws_security_group.wordpress-lb-sg.id]
  }
  
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups = [aws_security_group.wordpress-lb-sg.id]
  }
   egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################################
# Launch configuration
################################################################################
data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")
  vars = {
    EFS_MOUNT   = aws_efs_mount_target.wordpress-mount-targets[0].dns_name
    DB_NAME     = aws_rds_cluster.wordpress-rds-cluster.database_name
    DB_HOSTNAME = aws_rds_cluster.wordpress-rds-cluster.endpoint
    DB_USERNAME = aws_rds_cluster.wordpress-rds-cluster.master_username
    DB_PASSWORD = aws_rds_cluster.wordpress-rds-cluster.master_password
    LB_HOSTNAME = aws_alb.wordpress-loadbalancer.dns_name
  }
}

resource "aws_launch_configuration" "launch-conf" {
  name_prefix     = "wp-launch-conf"
  image_id        = "ami-0eab41619a08cc289"
  instance_type   = "t2.small"
  security_groups = [aws_security_group.wordpress-db-client-sg.id, #db
                      aws_security_group.wordpress-db-sg.id,  #db
                      aws_security_group.wordpress-servers-sg.id,  #servers
                      aws_security_group.wordpress-cache-sg.id, #cache
                      #aws_security_group.wordpress-lb-sg.id
                    ]
  #key_name        = "HaWorkshop"
  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Autoscaling group
################################################################################
resource "aws_autoscaling_group" "wordpress-autoscaling-group" {
  name                 = "wordpress-autoscaling-group"
  launch_configuration = aws_launch_configuration.launch-conf.name
  min_size             = 2
  max_size             = 8
  vpc_zone_identifier  = module.vpc.private_subnets
  target_group_arns    = [aws_alb_target_group.wordpress-lb-target-group.arn]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "wordpress-asg-attachment" {
  autoscaling_group_name = aws_autoscaling_group.wordpress-autoscaling-group.id
  alb_target_group_arn   = aws_alb_target_group.wordpress-lb-target-group.arn
}
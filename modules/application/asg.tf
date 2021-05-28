#============================ WordPress Servers ================================
################################################################################
# Security groups for WordPress Server
################################################################################
resource "aws_security_group" "wordpress-servers-sg" {
  name = "${var.prefix_name}-servers-sg"

  description = "Allow HTTP, HTTPS and SSH connection from Load Balancer & Bastion"
  vpc_id      = var.vpc_id

  # Only lb in http & https
  ingress {
    from_port        = var.http_port
    to_port          = var.http_port
    protocol         = "tcp"
    security_groups = [aws_security_group.wordpress-lb-sg.id]
  }
  
  ingress {
    from_port        = var.https_port
    to_port          = var.https_port
    protocol         = "tcp"
    security_groups = [aws_security_group.wordpress-lb-sg.id]
  }
  ingress {
    from_port        = var.ssh_port
    to_port          = var.ssh_port
    protocol         = "tcp"
    security_groups = [module.bastion.security_group_id]
  }
    egress {
    from_port = var.http_port
    to_port   = var.http_port
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = var.https_port
    to_port   = var.https_port
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.prefix_name}-servers-sg"
    Terraform   = "true"
    Environment = "dev"
  }
}

################################################################################
# Launch configuration
################################################################################
data "template_file" "user_data" {
  template = file("${path.module}/install_apache.sh")
  vars = {
    EFS_MOUNT   = var.efs_dns_name
    DB_NAME     = var.db_name
    DB_HOSTNAME = var.db_hostname
    DB_USERNAME = var.db_username
    DB_PASSWORD = var.db_password
    LB_HOSTNAME = aws_alb.wordpress-loadbalancer.dns_name
  }
}

resource "aws_launch_configuration" "launch-conf" {
  # Launch Configurations cannot be updated after creation with the AWS API.
  # In order to update a Launch Configuration, Terraform will destroy the
  # existing resource and create a replacement.
  #
  # We're only setting the name_prefix here,
  # Terraform will add a random string at the end to keep it unique.
  name_prefix     = "${var.prefix_name}-worker"
  #ubuntu ami
  image_id        = "ami-063d4ab14480ac177" #var.ami

  instance_type   = var.vm_instance_type
  security_groups = concat(var.clients_sg, [aws_security_group.wordpress-servers-sg.id])
  key_name = var.key_name
  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }

  # tags = {
  #   Name        = "${var.prefix_name}-servers"
  #   Terraform   = "true"
  #   Environment = "dev"
  # }
}

################################################################################
# Autoscaling group
################################################################################
resource "aws_autoscaling_group" "wordpress-autoscaling-group" {
  # Force a redeployment when launch configuration changes.
  # This will reset the desired capacity if it was changed due to
  # autoscaling events.
  name                 = "${aws_launch_configuration.launch-conf.name}-asg"
  launch_configuration = aws_launch_configuration.launch-conf.name
  min_size             = var.asg_min_size
  max_size             = var.asg_max_size
  vpc_zone_identifier  = var.private_subnets
  target_group_arns    = [aws_alb_target_group.wordpress-lb-target-group.arn]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "wordpress-asg-attachment" {
  autoscaling_group_name = aws_autoscaling_group.wordpress-autoscaling-group.id
  alb_target_group_arn   = aws_alb_target_group.wordpress-lb-target-group.arn
}

################################################################################
# Bastion
################################################################################
module "bastion" {
  source = "umotif-public/bastion/aws"
  version = "~> 2.1.0"

  name_prefix    = "${var.prefix_name}"
  ami_id         = var.ami
  vpc_id         = var.vpc_id
  public_subnets = var.public_subnets

  ssh_key_name   = var.key_name

  bastion_instance_types= [var.vm_instance_type]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
#============================== SHARED FS ======================================
################################################################################
# Security groups for Elastic File System
################################################################################
resource "aws_security_group" "wordpress-fs-client-sg" {
  name = "${var.prefix_name}-fs-client-sg"

  description = "Allow wordpress servers to connect to EFS on 2049"
  vpc_id = var.vpc_id

  egress {
    from_port = var.efs_port
    to_port   = var.efs_port
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.prefix_name}-fs-client-sg"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "wordpress-fs-sg" {
  name = "${var.prefix_name}-fs-sg"

  description = "Allow TCP connection on 2049  for Elastic File System"
  vpc_id      = var.vpc_id

  # Only efs in
  ingress {
    from_port       = var.efs_port
    to_port         = var.efs_port
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress-fs-client-sg.id]
  }

  egress {
    from_port = var.efs_port
    to_port   = var.efs_port
    protocol  = "tcp"
    security_groups = [aws_security_group.wordpress-fs-client-sg.id]
  }

  tags = {
    Name        = "${var.prefix_name}-fs-sg"
    Terraform   = "true"
    Environment = "dev"
  }
}

################################################################################
# Elastic File System
################################################################################
resource "aws_efs_file_system" "wordpress-efs" {
  creation_token = "wordpress-efs"

  tags = {
    Name        = "${var.prefix_name}-fs"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_efs_mount_target" "wordpress-mount-targets" {
  count           = length(var.private_subnets)
  file_system_id  = aws_efs_file_system.wordpress-efs.id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [aws_security_group.wordpress-fs-sg.id]
}
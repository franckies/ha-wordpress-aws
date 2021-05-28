output "alb_dns" {
  value  = aws_alb.wordpress-loadbalancer.dns_name
}

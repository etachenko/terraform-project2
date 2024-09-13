# Output the Load Balancer DNS name
output "load_balancer_dns" {
  description = "The DNS name of the Load Balancer"
  value       = aws_lb.web_lb.dns_name
}

# Output the Auto Scaling Group ID
output "asg_id" {
  description = "The ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.web_asg.id
}

# Output the Security Group ID
output "security_group_id" {
  description = "The Security Group ID"
  value       = aws_security_group.web_sg.id
}

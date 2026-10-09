output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IPv4 address of the EC2 instance."
  value       = aws_instance.app.public_ip
}

output "application_url" {
  description = "HTTP URL of the demo application."
  value       = "http://${aws_instance.app.public_ip}"
}

output "security_group_id" {
  description = "ID of the security group."
  value       = aws_security_group.app.id
}

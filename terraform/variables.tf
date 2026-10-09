variable "aws_region" {
  description = "AWS region for this project."
  type        = string
  default     = "ap-south-1"
}

variable "aws_profile" {
  description = "AWS CLI profile used by Terraform."
  type        = string
  default     = "devops-project"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance."
  type        = string
  default     = "cloud-devops-cicd"
}

variable "allowed_ssh_cidr" {
  description = "Optional public IPv4 CIDR for SSH, e.g. 203.0.113.10/32. Blank disables SSH."
  type        = string
  default     = ""
}

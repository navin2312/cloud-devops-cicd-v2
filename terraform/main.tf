data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "app" {
  name        = "${var.instance_name}-sg"
  description = "Security group for the Cloud DevOps demo"

  ingress {
    description = "Public HTTP access to the demo page"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.allowed_ssh_cidr == "" ? [] : [var.allowed_ssh_cidr]
    content {
      description = "SSH only from the configured public IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Outbound access for updates and Docker image downloads"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.instance_name}-sg"
    Project = "cloud-devops-cicd"
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    dnf update -y
    dnf install -y docker
    systemctl enable --now docker

    mkdir -p /opt/cloud-devops-app
    cat > /opt/cloud-devops-app/index.html <<'HTML'
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Cloud DevOps CI/CD</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 0; background: #f3f6fb; color: #172033; }
        main { max-width: 760px; margin: 12vh auto; padding: 36px; background: white; border-radius: 16px; box-shadow: 0 8px 30px #18233a18; }
        h1 { color: #155eef; }
      </style>
    </head>
    <body>
      <main>
        <h1>Cloud DevOps CI/CD Project</h1>
        <p>Success! This EC2 instance was provisioned with Terraform.</p>
        <p>Next: automate deployment with Jenkins and Docker.</p>
      </main>
    </body>
    </html>
    HTML

    docker run -d --name cloud-devops-app --restart unless-stopped -p 80:80 -v /opt/cloud-devops-app/index.html:/usr/local/apache2/htdocs/index.html:ro httpd:2.4
  EOF

  user_data_replace_on_change = true

  tags = {
    Name    = var.instance_name
    Project = "cloud-devops-cicd"
  }

  depends_on = [aws_security_group.app]
}

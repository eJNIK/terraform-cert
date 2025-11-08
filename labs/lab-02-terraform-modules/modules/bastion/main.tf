resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = var.instance_type

  # Deploy to first public subnet created by module
  subnet_id = var.public_subnet_id

  vpc_security_group_ids = [aws_security_group.bastion.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              cat > /var/www/html/index.html <<'HTML'
              <html>
              <head><title>Terraform Modules Lab</title></head>
              <body>
                <h1>Hello from Terraform Lab 02!</h1>
                <h2>Using Terraform Modules</h2>
                <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
                <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
                <p><strong>VPC Module:</strong> Successfully deployed!</p>
              </body>
              </html>
              HTML
              EOF

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.owner_tag}-bastion"
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.owner_tag}-bastion-sg"
  description = "Security group for web server"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.owner_tag}-web-server-sg"
  }
}


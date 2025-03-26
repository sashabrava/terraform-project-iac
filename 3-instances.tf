# Create Ubuntu instance (with internet access)
resource "aws_instance" "ubuntu_instance" {
  ami                    = "ami-084568db4383264d4"
  instance_type          = "t2.micro"
  key_name               = "MyKeyPair"
  subnet_id              = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]
  # associate_public_ip_address = true # Public IP for internet access
  user_data_replace_on_change = true

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              echo "<html><body><h1>Hello World</h1> <div>$(lsb_release -d | cut -f2)</div></body></html>" > /var/www/html/index.html
              systemctl enable nginx
              systemctl start nginx

              # Docker Installation (Official Guide)
              apt-get install -y ca-certificates curl gnupg
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null
              chmod a+r /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io
              systemctl enable docker
              systemctl start docker
              EOF

  tags = {
    Name = "ubuntu-with-internet"
  }
}

# Create Amazon Linux instance (no internet access)
resource "aws_instance" "amazon_linux_instance" {
  ami                    = "ami-08b5b3a93ed654d19"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main_subnet.id
  key_name               = "MyKeyPair"
  vpc_security_group_ids = [aws_security_group.amazon_linux_sg.id]
  associate_public_ip_address = false # No public IP address
  user_data = <<-EOF
              #!/bin/bash
              echo "Amazon Linux instance with restricted network access"
              EOF

  tags = {
    Name = "amazon-linux-restricted"
  }
}

# Output the public IP of Ubuntu instance
output "ubuntu_public_ip" {
  value = aws_instance.ubuntu_instance.public_ip
}

# Output the private IPs of both instances
output "ubuntu_private_ip" {
  value = aws_instance.ubuntu_instance.private_ip
}

output "amazon_linux_private_ip" {
  value = aws_instance.amazon_linux_instance.private_ip
}
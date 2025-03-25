# Create Ubuntu instance (with internet access)
resource "aws_instance" "ubuntu_instance" {
  ami                    = "ami-084568db4383264d4"
  instance_type          = "t2.micro"
  key_name               = "MyKeyPair"
  subnet_id              = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]
  associate_public_ip_address = true # Public IP for internet access
  user_data_replace_on_change = true

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx ca-certificates curl fcgiwrap

              systemctl enable fcgiwrap
              systemctl start fcgiwrap
              
              cat > /var/www/html/lsb_release.cgi <<'LSB'
              #!/bin/bash
              echo "Content-type: text/plain"
              echo ""
              lsb_release -a
              LSB

              chmod +x /var/www/html/lsb_release.cgi

              # Configure nginx
              cat > /var/www/html/index.nginx-debian.html <<'INDEX'
              <html>
               <body>
                      <h1>Hello World!</h1>
                      <div class="info">
                        <!--#include virtual="/lsb_release.cgi" -->
                      </div>
                  </div>
              </body>
              </html>
              INDEX

             cat > /etc/nginx/sites-available/default <<'NGINX_CONFIG'
             server {
                listen 80 default_server;
                listen [::]:80 default_server;

                root /var/www/html;

                # Add index.php to the list if you are using PHP
                index index.html index.htm index.nginx-debian.html;

                server_name _;

                location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                ssi on;
                try_files $uri $uri/ =404;
                }
                location ~ \.cgi$ {
                    root /var/www/html;
                    fastcgi_pass unix:/var/run/fcgiwrap.socket;
                    include fastcgi_params;
                    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                }
                }
                NGINX_CONFIG

              systemctl enable nginx
              systemctl start nginx
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              chmod a+r /etc/apt/keyrings/docker.asc
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                            noble stable" | \
              tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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
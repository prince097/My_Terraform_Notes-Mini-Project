provider "aws" {
  region = "ap-south-1"
  access_key = ""
  secret_key = ""
}
# 1 . Create VPC
 resource "aws_vpc" "MYVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "New-VPC"
  }
}
# 2. Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.MYVPC.id

  tags = {
    Name = "my-internet-gateway"
  }
}

# 3. Create Custom Route Table
resource "aws_route_table" "My-Route-Table" {
  vpc_id = aws_vpc.MYVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "My-Route-Table"
  }
}
# 4. Create Subnet
resource "aws_subnet" "Subnet1" {
  vpc_id     = aws_vpc.MYVPC.id
  # In VPC_id we need VPC id from above which is why we used the .id along with other syntax,
  # we are referencing resource here.
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Prod-Subnet"
  }
}
# 5. Associate subnet to Route table.
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.Subnet1.id
  route_table_id = aws_route_table.My-Route-Table.id
}

# 6. Create security group
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.MYVPC.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr block we can provide our own device ip also so that the it only allows our device to access it.
  }
    ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
     }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web_traffic"
  }
}

# 7. Create network iterface.
resource "aws_network_interface" "web-server-network_interface" {
  subnet_id       = aws_subnet.Subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# 8. Create Elastic IP (For Public Access)
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-network_interface.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
#   we are providing this depends on for this reason:-EIP may require IGW to exist prior to association.
# Use depends_on to set an explicit dependency on the IGW.
  }

#   9. Create ubuntu server and Install/enable apache.
resource "aws_instance" "my-aws-instance" {
  ami           = "ami-02eb7a4783e7e9317"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a" 
  key_name = "terraform-project"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-network_interface.id
  }
  
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo My very first web server > /var/www/html/index.html'
                EOF
  
tags = {
    Name = "my-server"
  }
}
# For Printing Output
# output "server_private_ip" {
#   value = aws_instance.web-server-instance.private_ip

# }

# output "server_id" {
#   value = aws_instance.web-server-instance.id
# }

# For Assigining Varaible
# variable "subnet_prefix" {
#   description = "cidr block for the subnet"

# }

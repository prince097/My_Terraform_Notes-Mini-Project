provider "aws" {
  region = "ap-south-1"
  access_key = ""
  secret_key = ""
}

Creating EC2 Instance
resource "aws_instance" "myawsinstance" {
  ami           = "ami-02eb7a4783e7e9317"
  instance_type = "t2.micro"
  tags = {
    Name = "Server-1"
  }
}

resource "aws_instance" "myawsinstance2" {
  ami           = "ami-02eb7a4783e7e9317"
  instance_type = "t2.micro"
}

Creating VPC.
resource "aws_vpc" "MYVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Prod-VPC"
  }
}
# Creating Subnet
resource "aws_subnet" "Subnet1" {
  vpc_id     = aws_vpc.MYVPC.id
  # In VPC_id we need VPC id from above which is why we used the .id along with other syntax,
  # we are referencing resource here.
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Prod-Subnet"
  }
}

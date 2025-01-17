#terraform script to Create an EC2 instance for deploying safenet app along with VPC and Subnets

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
  access_key = "Paste your Access Key of ROOT Account"
  secret_key = "Paste your Secret Key of ROOT Account "
}
#create vpc
resource "aws_vpc" "safenetvpc" {
  cidr_block       = "10.8.0.0/16"
  instance_tenancy = "default"
}
#create internet gateway
resource "aws_internet_gateway" "safenetgw" {
  vpc_id = aws_vpc.safenetvpc.id
}
#create custom route table
resource "aws_route_table" "safenetroute" {
  vpc_id = aws_vpc.safenetvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.safenetgw.id
  }

  

  tags = {
    Name = "prod"
  }
}
#create a subnet
resource "aws_subnet" "safenetsubnet" {
  vpc_id     = aws_vpc.testvpc.id
  cidr_block = "10.8.1.0/24"
  availability_zone = "ap-south-1a"
}

#Associate subnet with route table
resource "aws_route_table_association" "testassociation" {
  subnet_id      = aws_subnet.safenetsubnet.id
  route_table_id = aws_route_table.safenetroute.id
}
#create security group to allow 22,3000 port
resource "aws_security_group" "allow_tls" {
  name        = "allow_traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.safenetvpc.id

  ingress {
    description = "Application Port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "SSH"
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
    Name = "allow_rules"
  }
}
# create a network interface with an ip  in the subnet that was created in step 4
resource "aws_network_interface" "testnic" {
  subnet_id       = aws_subnet.safenetsubnet.id
  private_ips     = ["10.8.1.50"]
  security_groups = [aws_security_group.allow_tls.id]
}
# Assign an elastic ip to the network interface  created to the step 7
resource "aws_eip" "elastic_ip_to_nic" {
  vpc                       = true
  network_interface         = aws_network_interface.safenetnic.id
  associate_with_private_ip = "10.8.1.50"
  depends_on = [aws_internet_gateway.testgw]
}
# create AWS instance 
resource "aws_instance" "Safenet-app" {
  ami           = "ami-0a4a70bd98c6d6441"  
  instance_type = "t3.micro"
  availability_zone = "ap-south-1a"
  key_name = "Create a keypair in aws and add  keyname which you have created"
  
  network_interface {
       device_index         = 0
       network_interface_id = aws_network_interface.safenetnic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get upgrade -y
              sudo apt install docker.io -y
              sudo service docker start
              sudo apt install git -y
              EOF   
}

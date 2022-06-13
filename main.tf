terraform {
  required_providers{
      aws = {
          source = "hashicorp/aws"
          version = "~> 4.17.1"
      }
  }
}

provider "aws"{  
  profile = "default" 
  region = "us-west-2"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet
  
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet  
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]  
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.igw]
  
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  } 
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  } 
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "sg_KK" {

  vpc_id = aws_vpc.main.id
    
  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
  description = "SSH from the internet"    
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["162.158.222.152/32"]
  }

  egress {
  from_port        = 0
  to_port          = 0
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "my_web2" {
  
  ami = "ami-0ca285d4c2cda3300"
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.sg_KK.id]
  subnet_id = aws_subnet.public.id
  associate_public_ip_address = true
  

  user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y
sudo systemctl enable nginx
sudo systemctl start nginx
EOF

  tags = {
    Name = "NGINX_WEB_Server Kirils_Kiselovs"
  }
}

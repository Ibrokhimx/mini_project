resource "aws_key_pair" "cloud_2024" {
  key_name   = "cloud_2024"
  public_key = file("~/.ssh/cloud_2024.pem.pub")
  lifecycle {
    ignore_changes = [public_key]
  }
}
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  for_each                = var.private_subnets
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  #map_public_ip_on_launch = true

  tags = {
    Name = each.value.name
  }
}
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  for_each                = var.public_subnets
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = each.value.name
  }
}
# module "subnets" {
#   source  = "app.terraform.io/pitt412/subnets/aws"
#   version = "1.0.4"
#   vpc_id  = aws_vpc.vpc.id
#   subnets = var.subnets
#   prefix  = var.prefix
# }

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.prefix}-public-rt"
  }
}

resource "aws_route_table_association" "rta" {
  for_each  = var.public_subnets
  subnet_id = aws_subnet.public_subnet[each.key].id
  #subnet_id      = [module.subnets.subnet_ids["public_subnets"]]
  route_table_id = aws_route_table.rt.id
}

module "security-groups" {
  source          = "app.terraform.io/pitt412/security-groups/aws"
  version         = "1.0.0"
  vpc_id          = aws_vpc.vpc.id
  security_groups = var.security-groups
}


resource "aws_instance" "server" {
  for_each      = var.ec2
  ami           = "ami-0230bd60aa48260c6"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.cloud_2024.key_name
  subnet_id     = aws_subnet.private_subnet[each.key].id
  #subnet_id              = module.subnets.private_subnet_ids[each.key]
  vpc_security_group_ids = [module.security-groups.security_group_id["Mini_proj_sg"]]
  user_data              = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd.service
              sudo systemctl enable httpd.service
              sudo echo "<h1> HELLO from ${each.value.server_name} </h1>" > /var/www/html/index.html                   
              EOF 

  tags = {
    Name = join("_", [var.prefix, each.key])
  }
}


resource "aws_nat_gateway" "ngw" {
  for_each      = var.public_subnets
  subnet_id     = aws_subnet.public_subnet[each.key].id
  allocation_id = aws_eip.nat[each.key].id
}
resource "aws_eip" "nat" {
  for_each = var.public_subnets
  domain   = "vpc"
}
resource "aws_route_table" "rt-nat" {
  vpc_id   = aws_vpc.vpc.id
  for_each = aws_nat_gateway.ngw
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw[each.key].id
  }
  tags = {
    Name = "${var.prefix}-private-rt"
  }
}
resource "aws_route_table_association" "rt-nat" {
  for_each  = var.private_subnets
  subnet_id = aws_subnet.private_subnet[each.key].id
  #subnet_id      = [module.subnets.subnet_ids["public_subnets"]]
  route_table_id = aws_route_table.rt-nat[each.key].id
}
# resource "aws_eip" "eip" {
#   for_each = var.ec2
#   instance = aws_instance.server[each.key].id
#   domain   = "vpc"
# }










# import {
#   to = aws_vpc.vpc
#   id = "vpc-025c34ef43eeab727"
# }
# import {
#   to = aws_key_pair.cloud_2024
#   id = "cloud_2024"
# }
# import {
#   to = aws_internet_gateway.igw
#   id = "igw-035e5da7721a5182f"
# }
# import {
#   to = aws_route_table.rt
#   id = "rtb-0e61bae9b99120873"
# }
# import {
#   to = module.subnets.aws_subnet.subnet["web"]
#   id = "subnet-00bbc069afd3975de"
# }
# import {
#   to = module.subnets.aws_subnet.subnet["dev"]
#   id = "subnet-088e69fa759032551"
# }
# import {
#   to = module.subnets.aws_subnet.subnet["app"]
#   id = "subnet-0dd6c4f87a1b0b1c1"
# }
# import {
#   to = aws_route_table_association.rta["app"]
#   id = "subnet-0dd6c4f87a1b0b1c1/rtb-0e61bae9b99120873"
# }
# import {
#   to = aws_route_table_association.rta["dev"]
#   id = "subnet-088e69fa759032551/rtb-0e61bae9b99120873"
# }
# import {
#   to = aws_route_table_association.rta["web"]
#   id = "subnet-00bbc069afd3975de/rtb-0e61bae9b99120873"
# }
# import {
#   to = aws_instance.server["dev"]
#   id = "i-00e96ca63808176cd"
# }
# import {
#   to = aws_instance.server["web"]
#   id = "i-09a11ccb990eea108"
# }
# import {
#   to = aws_instance.server["app"]
#   id = "i-0f59a57cc6427db5f"
# }
# import {
#   to = aws_eip.eip["web"]
#   id = "eipalloc-07472603fb65764b2"
# }
# import {
#   to = aws_eip.eip["app"]
#   id = "eipalloc-06921bcef5948c7be"
# }
# import {
#   to = aws_eip.eip["dev"]
#   id = "eipalloc-048ae6dadc5a14472"
# }
# import {
#   to = module.security-groups.aws_security_group.default["Mini_proj_sg"]
#   id = "sg-04ab75f6b3b74b58a"
# }

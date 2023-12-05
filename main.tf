resource "aws_key_pair" "cloud_2024" {
  key_name   = "cloud_2024"
  public_key = file("~/.ssh/cloud_2024.pem.pub")
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

# resource "aws_subnet" "subnet" {
#   vpc_id                  = aws_vpc.vpc.id
#   for_each                = var.subnets
#   cidr_block              = each.value.cidr_block
#   availability_zone       = each.value.availability_zone
#   map_public_ip_on_launch = true

#   tags = {
#     Name = each.value.name
#   }
# }
module "subnets" {
  source                  = "app.terraform.io/pitt412/subnets/aws"
  version                 = "1.0.4"
  #for_each = var.subnets
  vpc_id                  = aws_vpc.vpc.id
  subnets                 = var.subnets
  prefix                  = var.prefix
}

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
  for_each       = var.subnets
  subnet_id      = module.subnets.subnet_ids[each.key]
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
  subnet_id              = module.subnets.subnet_ids[each.key]
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

resource "aws_eip" "eip" {
  for_each = var.ec2
  instance = aws_instance.server[each.key].id
  domain   = "vpc"
}

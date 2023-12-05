variable "bambam" {
  type = string
}

variable "subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  default = {}
}

resource "aws_subnet" "main" {
  for_each          = var.subnets
  vpc_id            = var.bambam
  cidr_block        = each.value.cidr_block #cidrsubnet(data.aws_vpc.main.cidr_block, 4, 1)
  availability_zone = each.value.availability_zone
  tags = {
    Name = join("-", [var.prefix, "subnet"])
  }
}


variable "prefix" {
  type = string
}
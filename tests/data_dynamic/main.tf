variable "vpc_name" {
  type = string
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnets" "vpc_private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    Name = "private-subnet-*"
  }
}

data "aws_subnet" "vpc_private_subnets" {
  for_each = toset(data.aws_subnets.vpc_private_subnets.ids)
  id       = each.value
}

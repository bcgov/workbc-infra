# network.tf

data "aws_vpc" "main" {
  filter {
    name = "tag:Name"
    values = [var.vpc_name]
  }
}

provider "aws" {
  region = var.region1
}

provider "aws" {
  region = var.region2
  alias = "region2"
}

resource "random_pet" "this" {
  length = 2
}

locals {
  name  = "t360-demo"
  vpc_cidr = "10.0.0.0/16"
  vpc_cidr_secondary = "10.2.0.0/16"
  azs                          = slice(data.aws_availability_zones.available.names, 0, 3)
  azs_secondary                = slice(data.aws_availability_zones.secondary.names, 0, 3) 
  tags = {
    Project  = "t360-demo"
  }

}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_availability_zones" "secondary" {
  provider = aws.region2
}
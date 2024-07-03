module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)]
  single_nat_gateway = true
  enable_nat_gateway = true

  default_security_group_ingress = [ 
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "http-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  default_security_group_egress = [
    {
      protocol = "-1"
      from_port = 0
      to_port = 0
      cidr_blocks = "0.0.0.0/0"
    }
  ]


  tags = local.tags
}

module "vpc_secondary" {
  source  = "terraform-aws-modules/vpc/aws"

  providers = {
    aws = aws.region2
  }

  name = local.name
  cidr = local.vpc_cidr_secondary

  azs              = local.azs_secondary
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr_secondary, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr_secondary, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr_secondary, 8, k + 6)]
  single_nat_gateway = true
  enable_nat_gateway = true

  default_security_group_ingress = [ 
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "http-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  default_security_group_egress = [
    {
      protocol = "-1"
      from_port = 0
      to_port = 0
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = local.tags
}

###########################################
# endpoints
###########################################

module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  

  endpoints = {
    api_gateway = {
      service             = "execute-api"
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "api-gateway-vpc-endpoint" }
    }
  }

}

module "endpoints_secondary" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  providers = {
    aws  = aws.region2
  }

  vpc_id             = module.vpc_secondary.vpc_id

  endpoints = {
    api_gateway = {
      service             = "execute-api"
      subnet_ids          = module.vpc_secondary.private_subnets
      tags                = { Name = "api-gateway-vpc-endpoint" }
    }
  }

}

######################################
# VPC peering connection
######################################


resource "aws_vpc_peering_connection" "this" {
  peer_vpc_id   = module.vpc_secondary.vpc_id
  vpc_id        = module.vpc.vpc_id
  peer_region   = var.region2
  auto_accept   = false
}

resource "aws_vpc_peering_connection_accepter" "this" {
  provider                  = aws.region2
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

resource "aws_route" "primary_public" {
  route_table_id            = module.vpc.public_route_table_ids[0]
  destination_cidr_block    = local.vpc_cidr_secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "primary_private" {
  route_table_id            = module.vpc.private_route_table_ids[0]
  destination_cidr_block    = local.vpc_cidr_secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "secondary_private" {
  route_table_id            = module.vpc_secondary.private_route_table_ids[0]
  destination_cidr_block    = local.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id

  provider = aws.region2
}

resource "aws_route" "secondary_public" {
  route_table_id            = module.vpc_secondary.public_route_table_ids[0]
  destination_cidr_block    = local.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id

  provider = aws.region2
}
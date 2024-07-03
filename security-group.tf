module "LambdaSecurityGroup" {
  source = "terraform-aws-modules/security-group/aws"


  name        = "LambdaSecurityGroup"
  description = "Lambda Security Group"
  vpc_id      = module.vpc.vpc_id


  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  egress_with_cidr_blocks = [
    {
      protocol = "-1"
      from_port = 0
      to_port = 65535
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "LambdaSecurityGroup_secondary" {
  source = "terraform-aws-modules/security-group/aws"


  name        = "LambdaSecurityGroup"
  description = "Lambda Security Group"
  vpc_id      = module.vpc_secondary.vpc_id

  providers = {
    aws = aws.region2
  }


  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = module.vpc_secondary.vpc_cidr_block
    },
  ]

  egress_with_cidr_blocks = [
    {
      protocol = "-1"
      from_port = 0
      to_port = 65535
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}
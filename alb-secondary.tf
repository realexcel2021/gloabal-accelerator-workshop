
module "alb_secondary" {
  source = "terraform-aws-modules/alb/aws"

  name    = "t360-lb"
  vpc_id  = module.vpc_secondary.vpc_id
  subnets = module.vpc_secondary.public_subnets

  enable_deletion_protection = false

  providers = {
    aws  = aws.region2
  }



  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 443
      protocol = "HTTPS"
      certificate_arn             = module.acm_secondary.acm_certificate_arn
      forward = {
        target_group_key = "ex-ip"
      }
    }
    ex-http-https = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  target_groups = {
    ex-ip = {
      name_prefix               = "l1-"
      target_type               = "ip"
      protocol                  = "HTTPS"
      port                      = 443
      target_id                 = local.endpoint_secondary[0]
      health_check = {
        enabled             = true
        interval            = 35
        port                = 443
        healthy_threshold   = 3
        unhealthy_threshold = 5
        timeout             = 30
        protocol            = "HTTPS"
        matcher             = "403"
      }
    }
  }

  additional_target_group_attachments = {
    ip1 = {
      target_group_key = "ex-ip"
      target_id        =  local.endpoint_secondary[1]
      port             = 443
    }

    ip2 = {
      target_group_key = "ex-ip"
      target_id        =  local.endpoint_secondary[2]
      port             = 443
    }
  }

}
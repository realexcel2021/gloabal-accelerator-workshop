module "global_accelerator" {
  source = "terraform-aws-modules/global-accelerator/aws"

  name = "t360"

  flow_logs_enabled   = false
#   flow_logs_s3_bucket = "example-global-accelerator-flow-logs"
#   flow_logs_s3_prefix = "example"

  listeners = {
    listener_80 = {
      client_affinity = "SOURCE_IP"

      endpoint_group = {
        health_check_port             = 80
        health_check_protocol         = "HTTP"
        health_check_path             = "/"
        health_check_interval_seconds = 10
        health_check_timeout_seconds  = 5
        healthy_threshold_count       = 2
        unhealthy_threshold_count     = 2
        traffic_dial_percentage       = 100

        endpoint_configuration = [
        {
          client_ip_preservation_enabled = true
          endpoint_id                    = module.alb.arn
          weight                         = 100
        }

        ]

      }

      port_ranges = [
        {
          from_port = 80
          to_port   = 80
        }
      ]
      protocol = "TCP"
    }

    listener_443 = {
      client_affinity = "SOURCE_IP"

      endpoint_group = {
        health_check_port             = 443
        health_check_protocol         = "HTTPS"
        health_check_path             = "/"
        health_check_interval_seconds = 10
        health_check_timeout_seconds  = 5
        healthy_threshold_count       = 2
        unhealthy_threshold_count     = 2
        traffic_dial_percentage       = 100

        endpoint_configuration = [
        {
          client_ip_preservation_enabled = true
          endpoint_id                    = module.alb.arn
          weight                         = 100
        }

        ]

      }

      port_ranges = [
        {
          from_port = 443
          to_port   = 443
        }
      ]
      protocol = "TCP"
    }


  }

}

resource "aws_globalaccelerator_endpoint_group" "region2" {
  listener_arn = module.global_accelerator.listeners["listener_80"].id
  endpoint_group_region = var.region2

  endpoint_configuration {
    endpoint_id = module.alb_secondary.arn
    weight      = 100
  }
}

resource "aws_globalaccelerator_endpoint_group" "region443" {
  listener_arn = module.global_accelerator.listeners["listener_443"].id
  endpoint_group_region = var.region2

  endpoint_configuration {
    endpoint_id = module.alb_secondary.arn
    weight      = 100
  }
}
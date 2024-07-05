# module "acm" {
#   source  = "terraform-aws-modules/acm/aws"
#   version = "~> 4.0"

#   domain_name  = "${var.domain_name}"
#   zone_id      = var.zone_id

#   validation_method = "DNS"

#   subject_alternative_names = [
#     "*.${var.domain_name}",
#   ]

#   wait_for_validation = true

#   tags = {
#     Name = "${var.domain_name}"
#   }
# }

# module "acm_secondary" {
#   source  = "terraform-aws-modules/acm/aws"
#   version = "~> 4.0"

#   providers = {
#     aws = aws.region2
#   }

#   domain_name  = "${var.domain_name}"
#   zone_id      = var.zone_id

#   validation_method = "DNS"

#   subject_alternative_names = [
#     "*.${var.domain_name}",
#   ]

#   wait_for_validation = true

#   tags = {
#     Name = "${var.domain_name}"
#   }
# }
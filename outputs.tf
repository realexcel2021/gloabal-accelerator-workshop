output "alb_region1" {
  value = module.alb.dns_name
}

output "alb_region2" {
  value = module.alb_secondary.dns_name
}
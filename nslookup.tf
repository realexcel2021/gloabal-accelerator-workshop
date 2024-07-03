data "dns_a_record_set" "primary" {
  host = module.endpoints.endpoints["api_gateway"].dns_entry[0].dns_name
}

data "dns_a_record_set" "secondary" {
  host = module.endpoints_secondary.endpoints["api_gateway"].dns_entry[0].dns_name
}

locals {
  endpoint_primary = tolist(data.dns_a_record_set.primary.addrs)
  endpoint_secondary = tolist(data.dns_a_record_set.secondary.addrs)
}


locals {
  endpoint = module.aurora_postgresql_v2_primary.cluster_instances["one"].endpoint
  identifier = module.aurora_postgresql_v2_primary.cluster_instances["one"].id
}

resource "random_password" "master" {
  length  = 20
  special = false
}

resource "aws_secretsmanager_secret" "db_pass" {
  name = "database-terraform_secret_qwq"
  recovery_window_in_days = 0

  replica {
    region = var.region2
  }

}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.db_pass.id #remittance
  secret_string = <<EOF
    {
    "password": "${random_password.master.result}", 
    "dbname": "remittance", 
    "engine": "postgres", 
    "port": 5432, 
    "dbInstanceIdentifier": "${local.identifier}", 
    "host": "${local.endpoint}", 
    "username": "t360"
    }
  EOF
}

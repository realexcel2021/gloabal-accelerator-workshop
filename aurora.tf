
################################################################################
# PostgreSQL Serverless v2
################################################################################

data "aws_rds_engine_version" "postgresql" {
  engine  = "aurora-postgresql"
  version = "14.8"
}

resource "aws_rds_global_cluster" "this" {
  global_cluster_identifier = var.project_name
  engine                    = "aurora-postgresql"
  engine_version            = "14.8"
  database_name             = "remittance"
  storage_encrypted         = true

}


module "aurora_postgresql_v2_primary" {
  source = "terraform-aws-modules/rds-aurora/aws"

  name              = "${var.project_name}-primary" # primary-demo-cluster
  engine            = data.aws_rds_engine_version.postgresql.engine
  engine_mode       = "provisioned"
  engine_version    = data.aws_rds_engine_version.postgresql.version
  storage_encrypted = true
  master_username   = "t360"
  database_name     = "remittance" 
  global_cluster_identifier = aws_rds_global_cluster.this.id
  master_password   = random_password.master.result 
  manage_master_user_password = false
  kms_key_id = aws_kms_key.primary.arn
  enable_http_endpoint = true


  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
    vpc_secondary_ingress = {
      cidr_blocks = [module.vpc_secondary.vpc_cidr_block]
    }
  }

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true

  serverlessv2_scaling_configuration = {
    min_capacity = 0.5
    max_capacity = 10
  }

  instance_class = "db.serverless"
  instances = {
    one = {
      name = "${var.project_name}-primary-instance1"
    }
  }

  tags = local.tags
}

module "aurora_postgresql_v2_secondary" {
  source = "terraform-aws-modules/rds-aurora/aws"

  providers = {
    aws = aws.region2
  }

  name              = "${var.project_name}-secondary"
  engine            = data.aws_rds_engine_version.postgresql.engine
  engine_mode       = "provisioned"
  engine_version    = data.aws_rds_engine_version.postgresql.version
  storage_encrypted = true
  #master_username   = "root"
  global_cluster_identifier = aws_rds_global_cluster.this.id
  source_region = var.region1
  kms_key_id = aws_kms_key.secondary.arn
  enable_http_endpoint = true


  vpc_id               = module.vpc_secondary.vpc_id
  db_subnet_group_name = module.vpc_secondary.database_subnet_group_name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = [module.vpc_secondary.vpc_cidr_block]
    }
    vpc_secondary_ingress = {
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true
  #enable_global_write_forwarding = true

  serverlessv2_scaling_configuration = {
    min_capacity = 0.5
    max_capacity = 10
  }

  instance_class = "db.serverless"
  instances = {
    one = {
  
    }
  }

  depends_on = [ module.aurora_postgresql_v2_primary ]

  tags = local.tags
}




################################################################################
# Supporting Resources
################################################################################

data "aws_iam_policy_document" "rds" {
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        data.aws_caller_identity.current.arn,
      ]
    }
  }

  statement {
    sid = "Allow use of the key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [
        "monitoring.rds.amazonaws.com",
        "rds.amazonaws.com",
      ]
    }
  }
}

resource "aws_kms_key" "primary" {
  policy = data.aws_iam_policy_document.rds.json
  tags   = local.tags
}

resource "aws_kms_key" "secondary" {
  provider = aws.region2

  policy = data.aws_iam_policy_document.rds.json
  tags   = local.tags
}
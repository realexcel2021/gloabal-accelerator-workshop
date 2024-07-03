module "lambda_secondary" { # loadbalancer guy here!
  source = "terraform-aws-modules/lambda/aws"

  allowed_triggers = {
  }

  providers = {
    aws = aws.region2
  }


  function_name = "Website-global-accelerator"
  role_name     = "Website-global-accelerator-secondary"
  description   = "Serves as the root handler behind the Web ALB"  
  handler       = "main.lambda_handler"
  runtime       = "python3.11"
  architectures = ["x86_64"]
  timeout       = 60
  tracing_mode  = "PassThrough"
  publish       = true
  store_on_s3   = false
  memory_size   = 128

  source_path = "${path.module}/src/demo/"

  vpc_subnet_ids = module.vpc_secondary.private_subnets
  vpc_security_group_ids = [module.LambdaSecurityGroup_secondary.security_group_id]

   attach_policies    = true
   number_of_policies = 2
   policies           = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
}

resource "aws_lambda_layer_version" "lambda_layer_sec" {
  filename   = "src/python-layer.zip"
  layer_name = "t360-layer"

  provider = aws.region2

  compatible_runtimes = ["python3.11", "python3.9", "python3.10", "python3.8"]
}


module "CreateRemittanceTableLambdaFunction_secondary" {
  source = "terraform-aws-modules/lambda/aws"
  layers = [ aws_lambda_layer_version.lambda_layer_sec.arn, "arn:aws:lambda:${var.region2}:580247275435:layer:LambdaInsightsExtension:21" ]

  providers = {
    aws = aws.region2
  }


  function_name = "tf-CreateRemittanceTable-secondary"
  handler       = "api.create_remittance_table"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  timeout       = 900
  tracing_mode  = "Active"
  publish       = true
  store_on_s3   = false
  memory_size   = 1024

  source_path = "${path.module}/src/Api/"

  vpc_subnet_ids = module.vpc_secondary.private_subnets
  vpc_security_group_ids = [module.LambdaSecurityGroup_secondary.security_group_id]

   attach_policies    = true
   policies           = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
   number_of_policies = 2

   attach_policy_statements = true
   policy_statements = {
     ec2 = {
       effect    = "Allow",
       actions   = [
        "ec2:DescribeNetworkInterfaces", "ec2:CreateNetworkInterface", "ec2:DeleteNetworkInterface", "ec2:DescribeInstances", 
        "ec2:AttachNetworkInterface"
        ],
       resources = ["*"]
     }

     secrets_manager = {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resources = ["*"]
     }
     xray = {
      effect = "Allow"
      actions = [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ]
      resources = ["*"]
     }
    ssm = {
      effect = "Allow"
      actions = [
        "ssm:StartAutomationExecution"
      ]
      resources = ["*"]
    }
   }
}


module "GetRemittancesLambdaFunction_secondary" {
  source = "terraform-aws-modules/lambda/aws"
  layers = [ aws_lambda_layer_version.lambda_layer_sec.arn, "arn:aws:lambda:${var.region2}:580247275435:layer:LambdaInsightsExtension:21" ]

  providers = {
    aws = aws.region2
  }

  function_name = "tf-GetRemittances-secondary"
  handler       = "api.get_remittances"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  timeout       = 900
  tracing_mode  = "Active"
  publish       = true
  store_on_s3   = false
  memory_size   = 1024

  source_path = "${path.module}/src/Api/"

  vpc_subnet_ids = module.vpc_secondary.private_subnets
  vpc_security_group_ids = [module.LambdaSecurityGroup_secondary.security_group_id]

   attach_policies    = true
   policies           = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
   number_of_policies = 2

   attach_policy_statements = true
   policy_statements = {
     ec2 = {
       effect    = "Allow",
       actions   = [
        "ec2:DescribeNetworkInterfaces", "ec2:CreateNetworkInterface", "ec2:DeleteNetworkInterface", "ec2:DescribeInstances", 
        "ec2:AttachNetworkInterface"
        ],
       resources = ["*"]
     }

     secrets_manager = {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resources = ["*"]
     }
     xray = {
      effect = "Allow"
      actions = [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ]
      resources = ["*"]
     }
    ssm = {
      effect = "Allow"
      actions = [
        "ssm:StartAutomationExecution"
      ]
      resources = ["*"]
    }
   }
}


module "CreateRemittanceLambdaFunction_secondary" {
  source = "terraform-aws-modules/lambda/aws"
  layers = [ aws_lambda_layer_version.lambda_layer_sec.arn, "arn:aws:lambda:${var.region2}:580247275435:layer:LambdaInsightsExtension:21" ]

  providers = {
    aws = aws.region2
  }


  function_name = "tf-CreateRemittance-secondary"
  handler       = "api.create_remittance"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  timeout       = 900
  tracing_mode  = "Active"
  publish       = true
  store_on_s3   = false
  memory_size   = 1024

  source_path = "${path.module}/src/Api/"

  vpc_subnet_ids = module.vpc_secondary.private_subnets
  vpc_security_group_ids = [module.LambdaSecurityGroup_secondary.security_group_id]

   attach_policies    = true
   policies           = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
   number_of_policies = 2

   attach_policy_statements = true
   policy_statements = {
     ec2 = {
       effect    = "Allow",
       actions   = [
        "ec2:DescribeNetworkInterfaces", "ec2:CreateNetworkInterface", "ec2:DeleteNetworkInterface", "ec2:DescribeInstances", 
        "ec2:AttachNetworkInterface"
        ],
       resources = ["*"]
     }

     secrets_manager = {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resources = ["*"]
     }
     xray = {
      effect = "Allow"
      actions = [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ]
      resources = ["*"]
     }
    ssm = {
      effect = "Allow"
      actions = [
        "ssm:StartAutomationExecution"
      ]
      resources = ["*"]
    }
   }
}


# module "DeleteRemittanceLambdaFunction_secondary" {
#   source = "terraform-aws-modules/lambda/aws"
#   layers = [ aws_lambda_layer_version.lambda_layer_sec.arn, "arn:aws:lambda:${var.region2}:580247275435:layer:LambdaInsightsExtension:21" ]


#   function_name = "tf-DeleteRemittance"
#   handler       = "api.delete_remittance"
#   runtime       = "python3.8"
#   architectures = ["x86_64"]
#   timeout       = 900
#   tracing_mode  = "Active"
#   publish       = true
#   store_on_s3   = false
#   memory_size   = 1024

#   source_path = "${path.module}/src/Api/"

#   vpc_subnet_ids = module.vpc.private_subnets
#   vpc_security_group_ids = [module.LambdaSecurityGroup.security_group_id]

#    attach_policies    = true
#    policies           = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
#    number_of_policies = 2

#    attach_policy_statements = true
#    policy_statements = {
#      ec2 = {
#        effect    = "Allow",
#        actions   = [
#         "ec2:DescribeNetworkInterfaces", "ec2:CreateNetworkInterface", "ec2:DeleteNetworkInterface", "ec2:DescribeInstances", 
#         "ec2:AttachNetworkInterface"
#         ],
#        resources = ["*"]
#      }

#      secrets_manager = {
#       effect = "Allow"
#       actions = [
#         "secretsmanager:GetSecretValue"
#       ]
#       resources = ["*"]
#      }
#      xray = {
#       effect = "Allow"
#       actions = [
#         "xray:PutTraceSegments",
#         "xray:PutTelemetryRecords"
#       ]
#       resources = ["*"]
#      }
#     ssm = {
#       effect = "Allow"
#       actions = [
#         "ssm:StartAutomationExecution"
#       ]
#       resources = ["*"]
#     }
#    }
# }


# module "ClearRemittancesLambdaFunction_secondary" {
#   source = "terraform-aws-modules/lambda/aws"
#   layers = [ aws_lambda_layer_version.lambda_layer_sec.arn, "arn:aws:lambda:${var.region2}:580247275435:layer:LambdaInsightsExtension:21" ]


#   function_name = "tf-ClearRemittances"
#   handler       = "api.clear_remittances"
#   runtime       = "python3.8"
#   architectures = ["x86_64"]
#   timeout       = 900
#   tracing_mode  = "Active"
#   publish       = true
#   store_on_s3   = false
#   memory_size   = 1024

#   source_path = "${path.module}/src/Api/"

#   vpc_subnet_ids = module.vpc.private_subnets
#   vpc_security_group_ids = [module.LambdaSecurityGroup.security_group_id]

#    attach_policies    = true
#    policies           = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
#    number_of_policies = 2

#    attach_policy_statements = true
#    policy_statements = {
#      ec2 = {
#        effect    = "Allow",
#        actions   = [
#         "ec2:DescribeNetworkInterfaces", "ec2:CreateNetworkInterface", "ec2:DeleteNetworkInterface", "ec2:DescribeInstances", 
#         "ec2:AttachNetworkInterface"
#         ],
#        resources = ["*"]
#      }

#      secrets_manager = {
#       effect = "Allow"
#       actions = [
#         "secretsmanager:GetSecretValue"
#       ]
#       resources = ["*"]
#      }
#      xray = {
#       effect = "Allow"
#       actions = [
#         "xray:PutTraceSegments",
#         "xray:PutTelemetryRecords"
#       ]
#       resources = ["*"]
#      }
#     ssm = {
#       effect = "Allow"
#       actions = [
#         "ssm:StartAutomationExecution"
#       ]
#       resources = ["*"]
#     }
#    }
# }

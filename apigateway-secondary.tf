resource "aws_api_gateway_rest_api" "my_api_secondary" {
  name = "t360-rest-api"
  description = "rest api"

  provider = aws.region2

  endpoint_configuration {
    types = ["PRIVATE"]
    vpc_endpoint_ids = [module.endpoints_secondary.endpoints["api_gateway"].id]
  }
}

resource "aws_api_gateway_rest_api_policy" "this_secondary" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  policy      = data.aws_iam_policy_document.apigateway_access_secondary.json

  provider = aws.region2
}

resource "aws_api_gateway_deployment" "deployment_secondary" {
  depends_on = [
    aws_api_gateway_integration.demo_secondary,
    aws_api_gateway_method.demo_secondary,
    aws_api_gateway_rest_api_policy.this_secondary
  ]

  provider = aws.region2  

  lifecycle {
    create_before_destroy = true
  }

triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.demo_secondary,
      aws_api_gateway_integration.demo_secondary,
      aws_api_gateway_rest_api_policy.this_secondary,

      aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_sec_options,
      aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_sec,
      aws_api_gateway_integration.ApiGatewayMethodCreateRemittanceTable_sec,
      aws_api_gateway_integration.ApiGatewayMethodCreateRemittanceTable_sec_options,

      aws_api_gateway_method.ApiGatewayMethodGetRemittances_sec,
        aws_api_gateway_method.ApiGatewayMethodGetRemittances_sec_options,
        aws_api_gateway_integration.ApiGatewayMethodGetRemittances_sec_options,
        aws_api_gateway_integration.ApiGatewayMethodGetRemittances_sec,

        aws_api_gateway_method.ResourceCreateRemittance_sec,
        aws_api_gateway_method.ResourceCreateRemittance_sec_options,
        aws_api_gateway_integration.ResourceCreateRemittance_sec
    ]))
  }

  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
}

resource "aws_api_gateway_domain_name" "this_secondary" {
  regional_certificate_arn = var.acm_certificate_arn_secondary
  domain_name     = "${var.domain_name}"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  provider = aws.region2
  
}

resource "aws_api_gateway_base_path_mapping" "this_secondary" {
  api_id      = aws_api_gateway_rest_api.my_api_secondary.id
  stage_name  = aws_api_gateway_stage.this_secondary.stage_name
  domain_name = aws_api_gateway_domain_name.this_secondary.domain_name
  provider = aws.region2

  depends_on = [ aws_api_gateway_deployment.deployment_secondary ]
}

resource "aws_api_gateway_stage" "this_secondary" {
  deployment_id = aws_api_gateway_deployment.deployment_secondary.id
  rest_api_id   = aws_api_gateway_rest_api.my_api_secondary.id
  stage_name    = "dev"
    provider = aws.region2
}

resource "aws_api_gateway_resource" "demo_secondary" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  parent_id = aws_api_gateway_rest_api.my_api_secondary.root_resource_id
  path_part = "get-region"
    provider = aws.region2
}

resource "aws_api_gateway_method" "demo_secondary" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.demo_secondary.id
  http_method = "POST"
  authorization = "NONE"
    provider = aws.region2
}

resource "aws_api_gateway_integration" "demo_secondary" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.demo_secondary.id
  http_method = aws_api_gateway_method.demo_secondary.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.lambda_secondary.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
    provider = aws.region2
}

resource "aws_api_gateway_method_response" "demo_secondary" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.demo_secondary.id
  http_method = aws_api_gateway_method.demo_secondary.http_method
  status_code = "200"
    provider = aws.region2

  //cors section
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }

}

resource "aws_api_gateway_integration_response" "demo_secondary" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.demo_secondary.id
  http_method = aws_api_gateway_method.demo_secondary.http_method
  status_code = aws_api_gateway_method_response.demo_secondary.status_code
    provider = aws.region2


  //cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
}

  depends_on = [
    aws_api_gateway_method.demo_secondary,
    aws_api_gateway_integration.demo_secondary
  ]
}


##########################################
# create item method
##########################################

resource "aws_api_gateway_resource" "ApiGatewayMethodCreateRemittanceTable_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  parent_id = aws_api_gateway_rest_api.my_api_secondary.root_resource_id
  path_part = "create-tickets-table"
      provider = aws.region2
}

resource "aws_api_gateway_method" "ApiGatewayMethodCreateRemittanceTable_sec_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable_sec.id
  http_method = "OPTIONS"
  authorization = "NONE"
      provider = aws.region2
}

resource "aws_api_gateway_method" "ApiGatewayMethodCreateRemittanceTable_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable_sec.id
  http_method = "POST"
  authorization = "NONE"
      provider = aws.region2
}

resource "aws_api_gateway_integration" "ApiGatewayMethodCreateRemittanceTable_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable_sec.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_sec.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.CreateRemittanceTableLambdaFunction_secondary.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
      provider = aws.region2
}

resource "aws_api_gateway_integration" "ApiGatewayMethodCreateRemittanceTable_sec_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable_sec.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_sec_options.http_method
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
      provider = aws.region2

  request_templates = {
    "application/json" = jsonencode({statusCode = 200})
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodCreateRemittanceTable_sec_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable_sec.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_sec_options.http_method
  status_code = "200"
      provider = aws.region2


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodCreateRemittanceTable_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable_sec.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_sec.http_method
  status_code = "200"
      provider = aws.region2


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodCreateRemittanceTable_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable_sec.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_sec_options.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodCreateRemittanceTable_sec_options.status_code
    provider = aws.region2  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_sec,
    aws_api_gateway_integration.ApiGatewayMethodCreateRemittanceTable_sec_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodCreateRemittanceTable_sec_get" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable_sec.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_sec.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodCreateRemittanceTable_sec.status_code
      provider = aws.region2

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_sec,
    aws_api_gateway_integration.ApiGatewayMethodCreateRemittanceTable_sec
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'",
  }
}


############################################
# Get remittance 
############################################

resource "aws_api_gateway_resource" "ApiGatewayMethodGetRemittances_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  parent_id = aws_api_gateway_rest_api.my_api_secondary.root_resource_id
  provider = aws.region2
  path_part = "get-tickets"
}

resource "aws_api_gateway_method" "ApiGatewayMethodGetRemittances_sec_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances_sec.id
  http_method = "OPTIONS"
  authorization = "NONE"
  provider = aws.region2
}

resource "aws_api_gateway_method" "ApiGatewayMethodGetRemittances_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances_sec.id
  http_method = "GET"
  authorization = "NONE"
  provider = aws.region2
}


resource "aws_api_gateway_integration" "ApiGatewayMethodGetRemittances_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances_sec.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRemittances_sec.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.GetRemittancesLambdaFunction_secondary.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
  provider = aws.region2
}

resource "aws_api_gateway_integration" "ApiGatewayMethodGetRemittances_sec_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances_sec.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRemittances_sec_options.http_method
  type = "MOCK"
  provider = aws.region2
  passthrough_behavior = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = "'{\"statusCode\": 200}'"
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodGetRemittances_sec_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances_sec.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRemittances_sec_options.http_method
  status_code = "200"
  provider = aws.region2


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodGetRemittances_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances_sec.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRemittances_sec_options.http_method
  provider = aws.region2
  status_code = aws_api_gateway_method_response.ApiGatewayMethodGetRemittances_sec_options.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodGetRemittances_sec,
    aws_api_gateway_integration.ApiGatewayMethodGetRemittances_sec_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = "''"
  }
}


############################################
# Create remittance 
############################################

resource "aws_api_gateway_resource" "ResourceCreateRemittance_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  parent_id = aws_api_gateway_rest_api.my_api_secondary.root_resource_id
  provider = aws.region2
  path_part = "create-ticket"
}

resource "aws_api_gateway_method" "ResourceCreateRemittance_sec_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance_sec.id
  http_method = "OPTIONS"
  authorization = "NONE"
  provider = aws.region2
}

resource "aws_api_gateway_method" "ResourceCreateRemittance_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance_sec.id
  http_method = "POST"
  authorization = "NONE"
  provider = aws.region2
}

resource "aws_api_gateway_method_settings" "ResourceCreateRemittance_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  stage_name  = aws_api_gateway_stage.this_secondary.stage_name
  method_path = "*/*"
  provider = aws.region2

  settings {
    metrics_enabled = false
    logging_level   = "OFF"
  }
}

resource "aws_api_gateway_integration" "ResourceCreateRemittance_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance_sec.id
  http_method = aws_api_gateway_method.ResourceCreateRemittance_sec.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.CreateRemittanceLambdaFunction_secondary.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
  provider = aws.region2
}

resource "aws_api_gateway_integration" "ResourceCreateRemittance_sec_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance_sec.id
  http_method = aws_api_gateway_method.ResourceCreateRemittance_sec_options.http_method
  provider = aws.region2
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = "'{\"statusCode\": 200}'"
  }
}

resource "aws_api_gateway_method_response" "ResourceCreateRemittance_sec_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance_sec.id
  http_method = aws_api_gateway_method.ResourceCreateRemittance_sec_options.http_method
  status_code = "200"
  provider = aws.region2


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "ResourceCreateRemittance_sec" {
  rest_api_id = aws_api_gateway_rest_api.my_api_secondary.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance_sec.id
  http_method = aws_api_gateway_method.ResourceCreateRemittance_sec_options.http_method
  provider = aws.region2
  status_code = aws_api_gateway_method_response.ResourceCreateRemittance_sec_options.status_code
  

  depends_on = [
    aws_api_gateway_method.ResourceCreateRemittance_sec,
    aws_api_gateway_integration.ResourceCreateRemittance_sec_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = "''"
  }
}

resource "aws_api_gateway_rest_api" "my_api" {
  name = "t360-rest-api"
  description = "rest api"

  endpoint_configuration {
    types = ["PRIVATE"]
    vpc_endpoint_ids = [module.endpoints.endpoints["api_gateway"].id]
  }
}

resource "aws_api_gateway_rest_api_policy" "this" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  policy      = data.aws_iam_policy_document.apigateway_access.json
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.demo,
    aws_api_gateway_method.demo,
    aws_api_gateway_rest_api_policy.this
  ]

  lifecycle {
    create_before_destroy = true
  }

triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.demo,
      aws_api_gateway_integration.demo,
      aws_api_gateway_rest_api_policy.this,


      aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_options,
      aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable,
      aws_api_gateway_integration.ApiGatewayMethodCreateRemittanceTable,
      aws_api_gateway_integration.ApiGatewayMethodCreateRemittanceTable_options,

      aws_api_gateway_method.ApiGatewayMethodGetRemittances,
      aws_api_gateway_method.ApiGatewayMethodGetRemittances_options,
      aws_api_gateway_integration.ApiGatewayMethodGetRemittances_options,
      aws_api_gateway_integration.ApiGatewayMethodGetRemittances,

      aws_api_gateway_method.ResourceCreateRemittance,
      aws_api_gateway_method.ResourceCreateRemittance_options,

    ]))
  }

  rest_api_id = aws_api_gateway_rest_api.my_api.id
}

resource "aws_api_gateway_domain_name" "this" {
  regional_certificate_arn = module.acm.acm_certificate_arn
  domain_name     = "${var.domain_name}"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
}

resource "aws_api_gateway_base_path_mapping" "this" {
  api_id      = aws_api_gateway_rest_api.my_api.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this.domain_name

  depends_on = [ aws_api_gateway_deployment.deployment ]
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  stage_name    = "dev"
}

##########################################
# Get region method
##########################################

resource "aws_api_gateway_resource" "demo" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "get-region"
}

resource "aws_api_gateway_method" "demo" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.demo.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "demo" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.demo.id
  http_method = aws_api_gateway_method.demo.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.lambda_primary.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
}

resource "aws_api_gateway_method_response" "demo" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.demo.id
  http_method = aws_api_gateway_method.demo.http_method
  status_code = "200"

  //cors section
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }

}

resource "aws_api_gateway_integration_response" "demo" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.demo.id
  http_method = aws_api_gateway_method.demo.http_method
  status_code = aws_api_gateway_method_response.demo.status_code


  //cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
}

  depends_on = [
    aws_api_gateway_method.demo,
    aws_api_gateway_integration.demo
  ]
}

##########################################
# create item method
##########################################

resource "aws_api_gateway_resource" "ApiGatewayMethodCreateRemittanceTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "create-tickets-table"
}

resource "aws_api_gateway_method" "ApiGatewayMethodCreateRemittanceTable_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "ApiGatewayMethodCreateRemittanceTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = false
    logging_level   = "OFF"
  }
}

resource "aws_api_gateway_integration" "ApiGatewayMethodCreateRemittanceTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.CreateRemittanceTableLambdaFunction.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
}

resource "aws_api_gateway_integration" "ApiGatewayMethodCreateRemittanceTable_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_options.http_method
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = jsonencode({statusCode = 200})
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodCreateRemittanceTable_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_options.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodCreateRemittanceTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodCreateRemittanceTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_options.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodCreateRemittanceTable_options.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable,
    aws_api_gateway_integration.ApiGatewayMethodCreateRemittanceTable_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodCreateRemittanceTable_get" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodCreateRemittanceTable.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable,
    aws_api_gateway_integration.ApiGatewayMethodCreateRemittanceTable
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'",
  }
}

###########################################
# Get remittance 
############################################

resource "aws_api_gateway_resource" "ApiGatewayMethodGetRemittances" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "get-tickets"
}

resource "aws_api_gateway_method" "ApiGatewayMethodGetRemittances_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances.id
  http_method = "OPTIONS"
  authorization = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_method" "ApiGatewayMethodGetRemittances" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "ApiGatewayMethodGetRemittances" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = false
    logging_level   = "OFF"
  }
}

resource "aws_api_gateway_integration" "ApiGatewayMethodGetRemittances" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRemittances.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.GetRemittancesLambdaFunction.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
}

resource "aws_api_gateway_integration" "ApiGatewayMethodGetRemittances_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRemittances_options.http_method
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = jsonencode({statusCode = 200})
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodGetRemittances_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRemittances_options.http_method
  status_code = "200"
  

  response_models = {
    "application/json" = "Empty"
  }


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false,
  }
}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodGetRemittances" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRemittances_options.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodGetRemittances_options.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodGetRemittances,
    aws_api_gateway_integration.ApiGatewayMethodGetRemittances_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = null
  }
}




############################################
# Create remittance 
############################################

resource "aws_api_gateway_resource" "ResourceCreateRemittance" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "create-ticket"
}

resource "aws_api_gateway_method" "ResourceCreateRemittance_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "ResourceCreateRemittance" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "ResourceCreateRemittance" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = false
    logging_level   = "OFF"
  }
}

resource "aws_api_gateway_integration" "ResourceCreateRemittance" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance.id
  http_method = aws_api_gateway_method.ResourceCreateRemittance.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.CreateRemittanceLambdaFunction.lambda_function_qualified_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
}

resource "aws_api_gateway_integration" "ResourceCreateRemittance_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance.id
  http_method = aws_api_gateway_method.ResourceCreateRemittance_options.http_method
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = jsonencode({statusCode = 200})
  }
}

resource "aws_api_gateway_method_response" "ResourceCreateRemittance_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance.id
  http_method = aws_api_gateway_method.ResourceCreateRemittance_options.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "ResourceCreateRemittance" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance.id
  http_method = aws_api_gateway_method.ResourceCreateRemittance_options.http_method
  status_code = aws_api_gateway_method_response.ResourceCreateRemittance_options.status_code
  

  depends_on = [
    aws_api_gateway_method.ResourceCreateRemittance,
    aws_api_gateway_integration.ResourceCreateRemittance_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = null
  }
}



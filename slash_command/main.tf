variable "name" {}
variable "region" {}
variable "source_code" {}
data "aws_caller_identity" "current" {}

# IAM
resource "aws_iam_role" "lambda" {
  name = "${var.name}_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role_policy.json}"
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions   = ["ssm:GetParameters"]
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.name}_slash_command_token"]
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "${var.name}_policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.lambda.json}"
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = "${aws_iam_role.lambda.name}"
  policy_arn = "${aws_iam_policy.lambda.arn}"
}

# Lambda
resource "aws_lambda_function" "lambda" {
  function_name    = "${var.name}"
  description      = "A function that handles a Slack slash command."

  runtime          = "python2.7"
  filename         = "${var.source_code}"
  source_code_hash = "${base64sha256(file(var.source_code))}"
  handler          = "${var.name}.lambda_handler"
  
  role             = "${aws_iam_role.lambda.arn}"
  memory_size      = "128"
  timeout          = "5"
}

resource "aws_lambda_permission" "allow_execution" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.function_name}"
  principal     = "apigateway.amazonaws.com"

  # http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*${aws_api_gateway_resource.resource.path}"
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.name}_api"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "${var.name}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.resource.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api.id}"
  resource_id             = "${aws_api_gateway_resource.resource.id}"
  http_method             = "${aws_api_gateway_method.method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda.arn}/invocations"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "production"
  depends_on = ["aws_api_gateway_integration.integration"]
}

# Output
output "command_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}${aws_api_gateway_resource.resource.path}"
}

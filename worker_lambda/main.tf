variable "name" {}
variable "region" {}
variable "source_code" {}
variable "sns_topic_arn" {}

resource "aws_iam_role" "lambda" {
  name = "${var.name}_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role_policy.json}"
}

# Cloudwatch
resource "aws_cloudwatch_log_group" "logs" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 1
}

# IAM
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
    actions   = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.logs.arn}"]
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

# SNS
resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = "${var.sns_topic_arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.lambda.arn}"
}

# Lambda
resource "aws_lambda_function" "lambda" {
  function_name    = "${var.name}"
  description      = "A function that fetches a meme."

  runtime          = "python2.7"
  filename         = "${var.name}.zip"
  source_code_hash = "${base64sha256(file("${var.name}.zip"))}"
  handler          = "${var.name}.lambda_handler"
  
  role             = "${aws_iam_role.lambda.arn}"
  memory_size      = "128"
  timeout          = "20"
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${var.sns_topic_arn}"
}

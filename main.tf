variable "region" {
  default = "ap-southeast-2"
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_sns_topic" "topic" {
  name = "meme_requests"
}

module "memebot" {
  source      = "github.com/tom-henderson/terraform-modules//slash-command"
  name        = "memebot"
  region      = "${var.region}"
  source_code = "memebot.zip"
  module_name = "memebot"

  ssm_parameters = ["catbot_slash_command_token"]

  environment_variables = {
    token_parameter = "memebot_slash_command_token"
    sns_arn         = "${aws_sns_topic.topic.arn}"
  }
}

data "aws_iam_policy_document" "allow_sns_publish" {
  statement {
    actions   = ["sns:Publish"]
    resources = ["${aws_sns_topic.topic.arn}"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.name}_policy"
  policy = "${data.aws_iam_policy_document.lambda.json}"
  role   = "${module.memebot.iam_role_name}"
}

module "memebot_worker" {
  source      = "github.com/tom-henderson/terraform-modules//lambda"
  name        = "memebot_worker_lambda"
  description = "A function that fetches a meme."
  source_code = "memebot.zip"
  module_name = "memebot_worker"

  environment_variables = {
    sns_arn = "${aws_sns_topic.topic.arn}"
  }
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = "${aws_sns_topic.topic.arn}"
  protocol  = "lambda"
  endpoint  = "${module.memebot_worker.lambda_arn}"
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${module.memebot_worker.lambda_function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.topic.arn}"
}

output "command_url" {
  value = "${module.memebot.slash_command_invocation_url}"
}
